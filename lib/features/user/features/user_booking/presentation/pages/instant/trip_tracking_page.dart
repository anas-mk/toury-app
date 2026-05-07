import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/services/location/mapbox_directions_service.dart';
import '../../../../../../../core/services/ratings/pending_rating_tracker.dart';
import '../../../../../../../core/services/signalr/booking_hub_events.dart';
import '../../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../../../../../../core/services/sos/active_sos_state.dart';
import '../../../../../../../core/services/sos/sos_service.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/app_payment_method.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import '../../widgets/instant/cancel_reason_sheet.dart';
import '../../widgets/sos/sos_active_banner.dart';
import '../../widgets/sos/sos_floating_button.dart';
import '../../widgets/sos/sos_sheet.dart';

/// Step 10 â€” live tracking screen. Listens to `HelperLocationUpdate` for
/// helper position + ETA, and to `BookingTripEnded` for completion.
class TripTrackingPage extends StatefulWidget {
  final InstantBookingCubit cubit;
  final String bookingId;
  final HelperSearchResult? helper;

  const TripTrackingPage({
    super.key,
    required this.cubit,
    required this.bookingId,
    this.helper,
  });

  @override
  State<TripTrackingPage> createState() => _TripTrackingPageState();
}

class _TripTrackingPageState extends State<TripTrackingPage> {
  late final BookingTrackingHubService _hub;
  late final SosService _sosService;
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _markerManager;
  PolylineAnnotationManager? _polylineManager;
  StreamSubscription<HelperLocationUpdateEvent>? _locationSub;
  StreamSubscription<BookingTripEndedEvent>? _tripEndedSub;
  StreamSubscription<ActiveSosState?>? _sosSub;

  HelperLocationUpdateEvent? _latest;
  ActiveSosState? _activeSos;
  bool _tripEnded = false;
  bool _cancelingSos = false;
  final _directions = MapboxDirectionsService();
  Timer? _routeDebounce;
  PointAnnotation? _helperPin;
  RouteResult? _lastRoute; // for the distance/ETA chip
  bool _mapReady = false;
  bool _isDisposed = false;
  bool _isDrawingRoute = false;
  bool _initialRouteDrawn = false;
  bool _tripEndHandled = false;

  @override
  void initState() {
    super.initState();
    _hub = sl<BookingTrackingHubService>();
    _sosService = sl<SosService>();
    _activeSos = _sosService.activeSos;
    _locationSub = _hub.helperLocationUpdateStream
        .where((e) => e.bookingId == widget.bookingId)
        .listen(_onLocation);
    _tripEndedSub = _hub.bookingTripEndedStream
        .where((e) => e.bookingId == widget.bookingId)
        .listen(_onTripEnded);
    _sosSub = _sosService.activeSosStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _activeSos = state?.bookingId == widget.bookingId ? state : null;
        if (_activeSos == null) {
          _cancelingSos = false;
        }
      });
    });
    _ensureConnected();
  }

  Future<void> _ensureConnected() async {
    try {
      await _hub.ensureConnected();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("TripTrackingPage: hub ensureConnected failed -> $e");
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _locationSub?.cancel();
    _tripEndedSub?.cancel();
    _sosSub?.cancel();
    _routeDebounce?.cancel();
    _mapboxMap = null;
    _markerManager = null;
    _polylineManager = null;
    _helperPin = null;
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _markerManager = await mapboxMap.annotations.createPointAnnotationManager();
    _polylineManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();
    _mapReady = true;
    // Draw route if booking already loaded
    final state = widget.cubit.state;
    final booking = _bookingFrom(state);
    if (booking != null) _drawRoute(booking);
  }

  // ── Route + markers ────────────────────────────────────────────────────

  /// Initial route from pickup → destination using the Directions API.
  void _drawRoute(BookingDetail booking) async {
    if (!_mapReady || _isDisposed || _isDrawingRoute) return;
    if (_polylineManager == null || _markerManager == null) return;
    _isDrawingRoute = true;
    try {
      await _polylineManager!.deleteAll();
      await _markerManager!.deleteAll();
    } on PlatformException {
      _isDrawingRoute = false;
      return;
    }
    _helperPin = null;

    final pickupLat = booking.pickupLatitude;
    final pickupLng = booking.pickupLongitude;
    final destLat = booking.destinationLatitude;
    final destLng = booking.destinationLongitude;

    // Pickup pin.
    try {
      await _markerManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(pickupLng, pickupLat)),
          iconImage: 'marker-15',
          iconSize: 1.8,
        ),
      );
    } on PlatformException {
      _isDrawingRoute = false;
      return;
    }
    // Destination pin.
    if (destLat != null && destLng != null) {
      try {
        await _markerManager!.create(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(destLng, destLat)),
            iconImage: 'marker-15',
            iconSize: 1.8,
          ),
        );
      } on PlatformException {
        _isDrawingRoute = false;
        return;
      }
    }

    if (destLat == null || destLng == null) {
      _isDrawingRoute = false;
      return;
    }

    // Fetch real route pickup → destination.
    try {
      await _fetchAndDrawPolyline(
        fromLat: pickupLat,
        fromLng: pickupLng,
        toLat: destLat,
        toLng: destLng,
      );
      _initialRouteDrawn = true;
    } finally {
      _isDrawingRoute = false;
    }
  }

  /// Draws the road-following polyline between two points.
  Future<void> _fetchAndDrawPolyline({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    if (!_mapReady || _isDisposed) return;
    final route = await _directions.getRoute(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      profile: 'driving',
    );

    if (!mounted) return;
    try {
      await _polylineManager?.deleteAll();
    } on PlatformException {
      return;
    }

    if (route == null || route.coordinates.isEmpty) {
      // Fallback straight line.
      try {
        await _polylineManager?.create(
          PolylineAnnotationOptions(
            geometry: LineString(
              coordinates: [Position(fromLng, fromLat), Position(toLng, toLat)],
            ),
            lineColor: AppColor.accentColor.toARGB32(),
            lineWidth: 3.5,
            lineOpacity: 0.55,
          ),
        );
      } on PlatformException {
        return;
      }
      return;
    }

    final positions = route.coordinates
        .map((c) => Position(c[0], c[1]))
        .toList();
    try {
      await _polylineManager?.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: positions),
          lineColor: AppColor.accentColor.toARGB32(),
          lineWidth: 5.0,
          lineOpacity: 0.88,
        ),
      );
    } on PlatformException {
      return;
    }

    // Show ETA chip.
    if (mounted) {
      setState(() => _lastRoute = route);
    }
  }

  void _onLocation(HelperLocationUpdateEvent event) {
    if (_isDisposed) return;
    setState(() {
      _latest = event;
    });

    // Smooth-follow camera.
    _mapboxMap?.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(event.longitude, event.latitude)),
        zoom: 16,
      ),
    );

    // Move helper marker in place.
    _updateHelperPin(event.latitude, event.longitude);

    // Re-fetch route from helper's new position → destination (debounced).
    if (_routeDebounce?.isActive != true) {
      _routeDebounce = Timer(const Duration(seconds: 10), () {});
      final booking = _bookingFrom(widget.cubit.state);
      if (booking != null &&
          booking.destinationLatitude != null &&
          booking.destinationLongitude != null) {
        _fetchAndDrawPolyline(
          fromLat: event.latitude,
          fromLng: event.longitude,
          toLat: booking.destinationLatitude!,
          toLng: booking.destinationLongitude!,
        );
      }
    }
  }

  /// Creates or moves the helper location marker without redrawing all pins.
  Future<void> _updateHelperPin(double lat, double lng) async {
    if (_markerManager == null || !_mapReady || _isDisposed) return;
    if (_helperPin != null) {
      try {
        await _markerManager!.delete(_helperPin!);
      } catch (_) {}
    }
    try {
      _helperPin = await _markerManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          iconImage: 'embassy-15', // distinct icon for the moving helper
          iconSize: 2.0,
        ),
      );
    } on PlatformException {
      return;
    }
  }

  void _onTripEnded(BookingTripEndedEvent event) {
    if (!mounted || _tripEndHandled) return;
    _tripEndHandled = true;
    setState(() {
      _tripEnded = true;
    });
    // Phase 4: mark this booking as pending-rating BEFORE we navigate
    // away. Even if the user kills the app the global overlay will
    // re-show it on next launch.
    unawaited(sl<PendingRatingTracker>().markPending(widget.bookingId));
    if (widget.cubit.selectedPaymentMethod == AppPaymentMethod.mockCard) {
      // Mock-card payment was already collected up front. Just go home;
      // the global mandatory rating overlay will handle the popup.
      context.go(AppRouter.bookingHome);
      return;
    }
    context.go(
      AppRouter.instantPayNow.replaceFirst(':id', widget.bookingId),
    );
  }

  Future<void> _onCancel(BuildContext ctx) async {
    final reason = await showCancelReasonSheet(
      ctx,
      refundToWallet:
          widget.cubit.selectedPaymentMethod == AppPaymentMethod.mockCard,
    );
    if (reason == null || !mounted) return;
    final ok = await widget.cubit.cancelBooking(widget.bookingId, reason);
    if (!ok || !mounted) return;
    if (!context.mounted) return;
    context.go(AppRouter.bookingHome);
  }

  Future<void> _callHelper(String? phone) async {
    final p = (phone ?? '').trim();
    if (p.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: p);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  void _openChat() {
    context.push(AppRouter.userChat.replaceFirst(':id', widget.bookingId));
  }

  Future<void> _openSosSheet() async {
    final ok = await showSosSheet(
      context,
      onTrigger: (result) async {
        final trigger = await _sosService.trigger(
          bookingId: widget.bookingId,
          reason: result.reason.apiValue,
          note: result.note,
        );
        if (trigger.success) {
          return null;
        }
        return trigger.message ?? 'Could not trigger SOS. Please try again.';
      },
    );
    if (ok != true || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Support has been alerted')));
  }

  Future<void> _cancelSos() async {
    if (_cancelingSos) return;
    setState(() {
      _cancelingSos = true;
    });
    final result = await _sosService.cancel();
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _cancelingSos = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SOS cancelled')));
      return;
    }
    setState(() {
      _cancelingSos = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Could not cancel SOS. Please retry.'),
      ),
    );
  }

  void _recenter() {
    if (_latest != null) {
      _mapboxMap?.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(_latest!.longitude, _latest!.latitude),
          ),
          zoom: 16,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go(AppRouter.home);
        },
        child: Scaffold(
          body: BlocBuilder<InstantBookingCubit, InstantBookingState>(
            builder: (context, state) {
              // Removed LatLng variables - now handled in _onMapCreated
              final booking = _bookingFrom(state);
              final sosButtonBottom =
                  MediaQuery.of(context).size.height * 0.32 + AppTheme.spaceMD;
              // Draw route whenever booking data is available and map is ready
              if (booking != null && _mapReady && !_initialRouteDrawn) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _drawRoute(booking),
                );
              }
              return Stack(
                children: [
                  MapWidget(
                    key: const ValueKey('tripTrackingMap'),
                    cameraOptions: CameraOptions(
                      center: Point(
                        coordinates: Position(
                          booking?.pickupLongitude ?? (_latest?.longitude ?? 0),
                          booking?.pickupLatitude ?? (_latest?.latitude ?? 0),
                        ),
                      ),
                      zoom: (booking == null ? 3.0 : 15.0),
                    ),
                    styleUri: MapboxStyles.LIGHT,
                    onMapCreated: _onMapCreated,
                  ),
                  // Top-left circular blurred back button.
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: AppTheme.spaceMD,
                    child: _BlurredCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.go(AppRouter.home),
                    ),
                  ),
                  // Top-right recenter.
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: AppTheme.spaceMD,
                    child: _BlurredCircleButton(
                      icon: Icons.my_location_rounded,
                      onTap: _recenter,
                    ),
                  ),
                  // OSM attribution.
                  const Positioned(
                    right: 6,
                    bottom: 6,
                    child: _OsmAttribution(),
                  ),
                  // Distance / ETA chip — top-center, visible once route loads.
                  if (_lastRoute != null)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _RouteInfoChip(
                          distance: _lastRoute!.distanceLabel,
                          duration: _lastRoute!.durationLabel,
                        ),
                      ),
                    ),
                  if (_activeSos != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SosActiveBanner(
                        onCancel: _cancelSos,
                        isCancelling: _cancelingSos,
                      ),
                    ),
                  if (!_tripEnded)
                    Positioned(
                      right: AppTheme.spaceMD,
                      bottom: sosButtonBottom,
                      child: SosFloatingButton(onPressed: _openSosSheet),
                    ),
                  // Draggable bottom sheet.
                  DraggableScrollableSheet(
                    initialChildSize: 0.32,
                    minChildSize: 0.18,
                    maxChildSize: 0.62,
                    builder: (context, scrollController) {
                      return _TrackingSheet(
                        scrollController: scrollController,
                        latest: _latest,
                        booking: booking,
                        helperImageUrl:
                            widget.helper?.profileImageUrl ??
                            booking?.helper?.profileImageUrl,
                        helperName:
                            widget.helper?.fullName ??
                            booking?.helper?.fullName ??
                            'Your helper',
                        onCall: () => _callHelper(booking?.helper?.phoneNumber),
                        onChat: _openChat,
                        onCancel: (booking?.canCancel ?? false)
                            ? () => _onCancel(context)
                            : null,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  BookingDetail? _bookingFrom(InstantBookingState s) {
    if (s is InstantBookingAccepted) return s.booking;
    if (s is InstantBookingWaiting) return s.booking;
    return null;
  }
}

class _BlurredCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BlurredCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.85),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}

/// Required by OpenStreetMap tile-usage policy.
class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Â© OpenStreetMap contributors',
        style: TextStyle(fontSize: 10, color: Colors.black87),
      ),
    );
  }
}

class _TrackingSheet extends StatelessWidget {
  final ScrollController scrollController;
  final HelperLocationUpdateEvent? latest;
  final BookingDetail? booking;
  final String? helperImageUrl;
  final String helperName;
  final VoidCallback onCall;
  final VoidCallback onChat;
  final VoidCallback? onCancel;

  const _TrackingSheet({
    required this.scrollController,
    required this.latest,
    required this.booking,
    required this.helperImageUrl,
    required this.helperName,
    required this.onCall,
    required this.onChat,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDestPhase = latest?.phase == 'ToDestination';
    final eta = isDestPhase
        ? latest?.etaToDestinationMinutes
        : latest?.etaToPickupMinutes;
    final distance = isDestPhase
        ? latest?.distanceToDestinationKm
        : latest?.distanceToPickupKm;

    final phaseLabel = latest == null
        ? 'Connectingâ€¦'
        : isDestPhase
        ? 'Heading to destination'
        : 'On the way to pickup';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLG,
          AppTheme.spaceMD,
          AppTheme.spaceLG,
          AppTheme.spaceLG,
        ),
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColor.lightBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              Stack(
                children: [
                  AppNetworkImage(
                    imageUrl: helperImageUrl,
                    width: 56,
                    height: 56,
                    borderRadius: 28,
                  ),
                  const Positioned(
                    right: -2,
                    bottom: -2,
                    child: Icon(
                      Icons.verified_rounded,
                      color: AppColor.accentColor,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      helperName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColor.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          phaseLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColor.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (eta != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMD,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColor.accentColor, AppColor.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$eta',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'min',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (distance != null) ...[
            const SizedBox(height: AppTheme.spaceMD),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColor.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.straighten_rounded,
                    size: 16,
                    color: AppColor.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${distance.toStringAsFixed(1)} km away',
                    style: const TextStyle(
                      color: AppColor.accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              Expanded(
                child: _SheetActionBtn(
                  icon: Icons.phone_rounded,
                  label: 'Call',
                  color: AppColor.secondaryColor,
                  onTap: onCall,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: _SheetActionBtn(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  color: AppColor.accentColor,
                  onTap: onChat,
                ),
              ),
            ],
          ),
          if (booking != null) ...[
            const SizedBox(height: AppTheme.spaceLG),
            _MiniRow(
              icon: Icons.trip_origin_rounded,
              color: AppColor.accentColor,
              label: 'Pickup',
              value: booking!.pickupLocationName,
            ),
            if ((booking!.destinationName ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              _MiniRow(
                icon: Icons.flag_rounded,
                color: AppColor.errorColor,
                label: 'Destination',
                value: booking!.destinationName!,
              ),
            ],
          ],
          if (onCancel != null) ...[
            const SizedBox(height: AppTheme.spaceLG),
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancel trip'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColor.errorColor,
                side: const BorderSide(color: AppColor.errorColor, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SheetActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SheetActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _MiniRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: AppTheme.spaceSM),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColor.lightTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Route Info Chip — distance & ETA floating on the map
// =============================================================================

class _RouteInfoChip extends StatelessWidget {
  final String distance;
  final String duration;
  const _RouteInfoChip({required this.distance, required this.duration});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Distance
              const Icon(
                Icons.straighten_rounded,
                size: 16,
                color: Color(0xFF1A73E8),
              ),
              const SizedBox(width: 6),
              Text(
                distance,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              // Divider
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 1,
                height: 16,
                color: const Color(0xFFE0E0E0),
              ),
              // Duration
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: Color(0xFF1A73E8),
              ),
              const SizedBox(width: 6),
              Text(
                duration,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
