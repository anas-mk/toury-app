import 'dart:async';
import 'package:flutter/foundation.dart' show ValueListenable, kDebugMode;
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
import '../../../../../../../core/theme/app_dimens.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../../core/widgets/app_snackbar.dart';
import '../../../../../../../core/widgets/map_tracking_chrome.dart';
import '../../../domain/entities/app_payment_method.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import '../../widgets/instant/cancel_reason_sheet.dart';
import '../../widgets/sos/sos_active_banner.dart';
import '../../widgets/sos/sos_floating_button.dart';
import '../../widgets/sos/sos_sheet.dart';

/// Step 10 — live tracking screen. Listens to `HelperLocationUpdate` for
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

  /// Live packets update often; isolate from full-page setState rebuilds.
  final ValueNotifier<HelperLocationUpdateEvent?> _liveLocation =
      ValueNotifier<HelperLocationUpdateEvent?>(null);
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
    _liveLocation.dispose();
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
    _liveLocation.value = event;

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
    context.go(AppRouter.instantPayNow.replaceFirst(':id', widget.bookingId));
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
      AppSnackbar.show(
        context,
        message: 'Could not open phone dialer',
        tone: AppSnackTone.warning,
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
    AppSnackbar.show(
      context,
      message: 'Support has been alerted',
      tone: AppSnackTone.success,
    );
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
      AppSnackbar.show(
        context,
        message: 'SOS cancelled',
        tone: AppSnackTone.success,
      );
      return;
    }
    setState(() {
      _cancelingSos = false;
    });
    AppSnackbar.show(
      context,
      message: result.message ?? 'Could not cancel SOS. Please retry.',
      tone: AppSnackTone.danger,
    );
  }

  void _recenter() {
    final live = _liveLocation.value;
    if (live != null) {
      _mapboxMap?.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(live.longitude, live.latitude)),
          zoom: 16,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetExtents = MapTrackingLayout.sheetExtents(context);
    final sosButtonBottom = MapTrackingLayout.floatingButtonBottomInset(
      context,
      sheetPeekFraction: sheetExtents.initial,
    );

    return BlocProvider.value(
      value: widget.cubit,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go(AppRouter.home);
        },
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              BlocSelector<
                InstantBookingCubit,
                InstantBookingState,
                BookingDetail?
              >(
                selector: _bookingFrom,
                builder: (context, booking) {
                  final liveLon = _liveLocation.value?.longitude ?? 0.0;
                  final liveLat = _liveLocation.value?.latitude ?? 0.0;
                  if (booking != null && _mapReady && !_initialRouteDrawn) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _drawRoute(booking),
                    );
                  }
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(
                        child: MapWidget(
                          key: const ValueKey('tripTrackingMap'),
                          cameraOptions: CameraOptions(
                            center: Point(
                              coordinates: Position(
                                booking?.pickupLongitude ?? liveLon,
                                booking?.pickupLatitude ?? liveLat,
                              ),
                            ),
                            zoom: (booking == null ? 3.0 : 15.0),
                          ),
                          styleUri: MapboxStyles.LIGHT,
                          onMapCreated: _onMapCreated,
                        ),
                      ),
                      DraggableScrollableSheet(
                        initialChildSize: sheetExtents.initial,
                        minChildSize: sheetExtents.min,
                        maxChildSize: sheetExtents.max,
                        builder: (context, scrollController) {
                          return _TrackingSheet(
                            scrollController: scrollController,
                            liveLocation: _liveLocation,
                            booking: booking,
                            helperImageUrl:
                                widget.helper?.profileImageUrl ??
                                booking?.helper?.profileImageUrl,
                            helperName:
                                widget.helper?.fullName ??
                                booking?.helper?.fullName ??
                                'Your helper',
                            onCall: () =>
                                _callHelper(booking?.helper?.phoneNumber),
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
              Positioned(
                top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                left: AppTheme.spaceMD,
                child: MapFloatingGlassButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.go(AppRouter.home),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                right: AppTheme.spaceMD,
                child: MapFloatingGlassButton(
                  icon: Icons.my_location_rounded,
                  onTap: _recenter,
                ),
              ),
              Positioned(
                right: AppSpacing.sm + AppSpacing.xs,
                bottom: AppSpacing.sm + AppSpacing.xs,
                child: const _OsmAttribution(),
              ),
              if (_lastRoute != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: MapRouteInfoChip(
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
            ],
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

class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceElevated.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        '\u00a9 OpenStreetMap contributors',
        style: theme.textTheme.labelSmall?.copyWith(
          color: palette.textSecondary,
        ),
      ),
    );
  }
}

class _TrackingSheet extends StatelessWidget {
  final ScrollController scrollController;
  final ValueListenable<HelperLocationUpdateEvent?> liveLocation;
  final BookingDetail? booking;
  final String? helperImageUrl;
  final String helperName;
  final VoidCallback onCall;
  final VoidCallback onChat;
  final VoidCallback? onCancel;

  const _TrackingSheet({
    required this.scrollController,
    required this.liveLocation,
    required this.booking,
    required this.helperImageUrl,
    required this.helperName,
    required this.onCall,
    required this.onChat,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return MapTrackingSheetSurface(
      child: ValueListenableBuilder<HelperLocationUpdateEvent?>(
        valueListenable: liveLocation,
        builder: (context, latest, _) {
          final theme = Theme.of(context);
          final palette = AppColors.of(context);

          final isDestPhase = latest?.phase == 'ToDestination';
          final eta = isDestPhase
              ? latest?.etaToDestinationMinutes
              : latest?.etaToPickupMinutes;
          final distance = isDestPhase
              ? latest?.distanceToDestinationKm
              : latest?.distanceToPickupKm;

          final phaseLabel = latest == null
              ? 'Connecting\u2026'
              : isDestPhase
              ? 'Heading to destination'
              : 'On the way to pickup';

          return ListView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              0,
              AppSpacing.xxl,
              AppSpacing.xxl + bottomInset,
            ),
            children: [
              const MapTrackingDragHandle(),
              Row(
                children: [
                  Stack(
                    children: [
                      AppNetworkImage(
                        imageUrl: helperImageUrl,
                        width: AppSize.avatarLg - AppSpacing.sm,
                        height: AppSize.avatarLg - AppSpacing.sm,
                        borderRadius: (AppSize.avatarLg - AppSpacing.sm) / 2,
                      ),
                      Positioned(
                        right: -AppSpacing.xxs,
                        bottom: -AppSpacing.xxs,
                        child: Icon(
                          Icons.verified_rounded,
                          color: palette.success,
                          size: AppSpacing.lg + AppSpacing.xxs,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: AppSpacing.lg),
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
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Container(
                              width: AppSpacing.sm,
                              height: AppSpacing.sm,
                              decoration: BoxDecoration(
                                color: palette.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                phaseLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: palette.textSecondary,
                                ),
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
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [palette.success, palette.primary],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
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
                          Text(
                            'min',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (distance != null) ...[
                SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: palette.successSoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.straighten_rounded,
                        size: AppSize.iconMd,
                        color: palette.success,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${distance.toStringAsFixed(1)} km away',
                        style: TextStyle(
                          color: palette.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _SheetActionBtn(
                      icon: Icons.phone_rounded,
                      label: 'Call',
                      color: palette.primary,
                      onTap: onCall,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _SheetActionBtn(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Chat',
                      color: palette.success,
                      onTap: onChat,
                    ),
                  ),
                ],
              ),
              if (booking != null) ...[
                SizedBox(height: AppSpacing.xxl),
                _MiniRow(
                  icon: Icons.trip_origin_rounded,
                  color: palette.success,
                  label: 'Pickup',
                  value: booking!.pickupLocationName,
                ),
                if ((booking!.destinationName ?? '').isNotEmpty) ...[
                  SizedBox(height: AppSpacing.xs + AppSpacing.xxs),
                  _MiniRow(
                    icon: Icons.flag_rounded,
                    color: palette.danger,
                    label: 'Destination',
                    value: booking!.destinationName!,
                  ),
                ],
              ],
              if (onCancel != null) ...[
                SizedBox(height: AppSpacing.xxl),
                OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Cancel trip'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSize.buttonMd),
                    foregroundColor: palette.danger,
                    side: BorderSide(color: palette.danger, width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
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
              color: AppColors.of(context).textSecondary,
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
