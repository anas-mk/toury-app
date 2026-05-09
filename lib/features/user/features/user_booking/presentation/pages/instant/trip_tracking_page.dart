import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/services/location/last_helper_location_store.dart';
import '../../../../../../../core/services/location/map_markers.dart';
import '../../../../../../../core/services/location/mapbox_directions_service.dart';
import '../../../../../../../core/services/ratings/pending_rating_tracker.dart';
import '../../../../../../../core/services/signalr/booking_hub_events.dart';
import '../../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../../../../../../core/services/sos/active_sos_state.dart';
import '../../../../../../../core/services/sos/sos_service.dart';
import '../../../../../../../core/models/tracking/tracking_point_entity.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/utils/number_format.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../../user_booking_tracking/domain/usecases/get_latest_location_usecase.dart';
import '../../../../user_chat/presentation/widgets/unread_chat_badge.dart';
import '../../../domain/entities/app_payment_method.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_status.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import '../../widgets/instant/cancel_reason_sheet.dart';
import '../../widgets/sos/sos_active_banner.dart';
import '../../widgets/sos/sos_sheet.dart';

/// Step 10 — live tracking screen (Pass #6 — 2026 editorial redesign).
///
/// Listens to `HelperLocationUpdate` for helper position + ETA, and to
/// `BookingTripEnded` for completion. Visual layer matches the new
/// RAFIQ live-track mockup:
///
///   • Light Mapbox base.
///   • Floating "{Helper} · {ETA} min away" status pill on top.
///   • Two stacked white circular floating buttons on the right
///     (chat, emergency/SOS, recenter).
///   • Bottom sheet with helper avatar, ETA card, animated progress
///     bar (pickup → destination), and Share/Contact CTAs.
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
  RouteResult? _lastRoute;

  /// Server-side snapshot from `GET /booking/{id}/tracking/latest`,
  /// fetched on mount so the ETA / helper pin show up on first paint
  /// without waiting for the next throttled SignalR tick (which can
  /// be 10+ seconds away).
  TrackingPointEntity? _primedSnapshot;

  /// Last-seen helper location restored from disk. Used when
  /// `/tracking/latest` returns null and SignalR is silent (helper
  /// went into a dead zone, app just opened, etc.) — keeps the user
  /// from staring at an empty map.
  LastHelperLocation? _persistedLast;

  // ── Cached marker PNGs ──────────────────────────────────────────────
  // Rendered once via `dart:ui` Canvas → PNG bytes so the
  // pickup/destination pins and the live helper dot are guaranteed
  // to show on `MapboxStyles.LIGHT` (which doesn't ship the
  // Streets sprite that contains `marker-15` / `embassy-15`).
  Uint8List? _pickupMarkerPng;
  Uint8List? _destinationMarkerPng;
  Uint8List? _helperMarkerPng;

  /// Set on first successful pickup/destination draw so subsequent
  /// rebuilds don't recreate the static markers (and accidentally
  /// wipe the live helper pin while doing it).
  bool _initialRouteDrawn = false;

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
    // Deep-link guard: if the cubit is fresh (e.g. user tapped the
    // home banner for an in-progress trip) hydrate it.
    final s = widget.cubit.state;
    if (s is! InstantBookingAccepted && s is! InstantBookingWaiting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.cubit.hydrateForTripDeepLink(widget.bookingId);
      });
    }
    _ensureConnected();
    _primeFromServer();
    _loadCachedSnapshot();
  }

  /// Hydrates the map with the last helper location we saw (from a
  /// previous session, or before SignalR dropped). The live stream
  /// always wins — this is purely a fallback so the user never sees
  /// an empty map after backgrounding the app.
  Future<void> _loadCachedSnapshot() async {
    final cached =
        await LastHelperLocationStore.instance.load(widget.bookingId);
    if (!mounted || cached == null) return;
    // Don't overwrite the live snapshot or REST prime — both are
    // fresher than this disk copy by construction.
    if (_latest != null || _primedSnapshot != null) return;
    setState(() => _persistedLast = cached);
    // Drop a helper pin at the last-known spot so the screen isn't
    // empty while we wait for the next realtime tick.
    _updateHelperPin(cached.latitude, cached.longitude);
  }

  /// Persists [event] for offline / reconnection scenarios. Best-
  /// effort — failures are swallowed inside the store.
  void _persistLatestLocation(HelperLocationUpdateEvent event) {
    final snap = LastHelperLocation(
      bookingId: widget.bookingId,
      latitude: event.latitude,
      longitude: event.longitude,
      heading: event.heading,
      speedKmh: event.speedKmh,
      etaToPickupMinutes: event.etaToPickupMinutes,
      etaToDestinationMinutes: event.etaToDestinationMinutes,
      phase: event.phase,
      capturedAt: event.capturedAt ?? DateTime.now().toUtc(),
    );
    LastHelperLocationStore.instance.save(snap);
  }

  /// Pulls the freshest server-known helper position so we can paint
  /// a useful UI from frame 1, instead of waiting for the next
  /// throttled `HelperLocationUpdate` (server enforces ≥10 s / 20 m
  /// between samples). Recommended by the realtime guide § 10.3
  /// ("on reconnect — prime the map").
  ///
  /// Backend confirmed (2026-05-09 review):
  ///   • Returns 200 + `data: null` when no GPS sample has been
  ///     recorded yet — that's totally normal right after accept.
  ///   • The REST shape carries position + phase only — NO ETA /
  ///     distance fields. Those are exclusive to the SignalR event,
  ///     so this prime gives us a map pin but the ETA shows up only
  ///     after the first realtime tick.
  Future<void> _primeFromServer() async {
    try {
      final result =
          await sl<GetLatestLocationUseCase>()(widget.bookingId);
      if (!mounted) return;
      result.fold(
        (failure) {
          // 403 (not authorised) or 404 (booking missing). Stay
          // silent — the SignalR stream will still wake us up the
          // moment the first sample arrives.
        },
        (point) {
          // `point` is nullable: `null` means "no sample yet" which
          // is the expected state in the gap between accept and
          // the helper's first throttled GPS broadcast. Don't
          // overwrite the live snapshot with null in that case.
          if (point != null) {
            setState(() => _primedSnapshot = point);
          }
        },
      );
    } catch (_) {
      // Fail silently — the live stream is the source of truth.
    }
  }

  Future<void> _ensureConnected() async {
    try {
      await _hub.ensureConnected();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TripTrackingPage: hub ensureConnected failed -> $e');
      }
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _tripEndedSub?.cancel();
    _sosSub?.cancel();
    _routeDebounce?.cancel();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _markerManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    _polylineManager =
        await mapboxMap.annotations.createPolylineAnnotationManager();
    final state = widget.cubit.state;
    final booking = _bookingFrom(state);
    if (booking != null) _drawRoute(booking);
  }

  /// Idempotently draws the static pickup + destination pins and
  /// the initial polyline. Safe to call on every BlocBuilder rebuild
  /// — internally guarded by [_initialRouteDrawn] so we don't
  /// recreate annotations every frame.
  ///
  /// IMPORTANT: this method NEVER touches the live helper pin. The
  /// previous implementation called `deleteAll()` here which wiped
  /// the helper marker on every status update — that's why the user
  /// only saw their own location and never the helper.
  Future<void> _drawRoute(BookingDetail booking) async {
    if (_polylineManager == null || _markerManager == null) return;
    if (_initialRouteDrawn) return;

    _pickupMarkerPng ??= await MapMarkers.pickupPin();
    _destinationMarkerPng ??= await MapMarkers.destinationPin();
    if (!mounted ||
        _polylineManager == null ||
        _markerManager == null) {
      return;
    }

    final pickupLat = booking.pickupLatitude;
    final pickupLng = booking.pickupLongitude;
    final destLat = booking.destinationLatitude;
    final destLng = booking.destinationLongitude;

    await _markerManager!.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(pickupLng, pickupLat)),
      // `image` overrides any icon name; we provide a PNG that
      // doesn't depend on the Mapbox Streets sprite.
      image: _pickupMarkerPng,
      iconAnchor: IconAnchor.BOTTOM,
    ));
    if (destLat != null && destLng != null) {
      await _markerManager!.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(destLng, destLat)),
        image: _destinationMarkerPng,
        iconAnchor: IconAnchor.BOTTOM,
      ));
    }

    _initialRouteDrawn = true;
    if (destLat == null || destLng == null) return;
    await _fetchAndDrawPolyline(
      fromLat: pickupLat,
      fromLng: pickupLng,
      toLat: destLat,
      toLng: destLng,
    );
    // Frame the whole journey on first paint so the user can see
    // pickup, destination and (once it lands) the helper at once.
    _fitBoundsToRoute(
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destLat: destLat,
      destLng: destLng,
    );
  }

  /// Centers + zooms the camera so both endpoints fit on screen
  /// with a comfortable margin. Used on first draw; live helper
  /// updates take over from there.
  Future<void> _fitBoundsToRoute({
    required double pickupLat,
    required double pickupLng,
    required double destLat,
    required double destLng,
  }) async {
    final m = _mapboxMap;
    if (m == null) return;
    final coords = [
      Point(coordinates: Position(pickupLng, pickupLat)),
      Point(coordinates: Position(destLng, destLat)),
    ];
    try {
      final cam = await m.cameraForCoordinatesPadding(
        coords,
        CameraOptions(),
        MbxEdgeInsets(top: 140, left: 60, bottom: 320, right: 60),
        null,
        null,
      );
      m.setCamera(cam);
    } catch (_) {/* keep last camera */}
  }

  /// Draws the road-following polyline between two points.
  Future<void> _fetchAndDrawPolyline({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final route = await _directions.getRoute(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      profile: 'driving',
    );

    if (!mounted) return;
    await _polylineManager?.deleteAll();

    if (route == null || route.coordinates.isEmpty) {
      // Fallback straight line.
      // ignore: deprecated_member_use
      final fallbackColor = AppColor.accentColor.value;
      await _polylineManager?.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: [
          Position(fromLng, fromLat),
          Position(toLng, toLat),
        ]),
        lineColor: fallbackColor,
        lineWidth: 3.5,
        lineOpacity: 0.55,
      ));
      return;
    }

    final positions =
        route.coordinates.map((c) => Position(c[0], c[1])).toList();
    // ignore: deprecated_member_use
    final mainColor = AppColor.accentColor.value;
    await _polylineManager?.create(PolylineAnnotationOptions(
      geometry: LineString(coordinates: positions),
      lineColor: mainColor,
      lineWidth: 5.0,
      lineOpacity: 0.88,
    ));
    if (mounted) {
      setState(() => _lastRoute = route);
    }
  }

  /// Whether [_onLocation] is currently allowed to redraw the
  /// polyline. We throttle this network call to once every 10 s so
  /// each GPS sample doesn't trigger a Mapbox Directions request.
  bool _routeRefreshAllowed = true;

  void _onLocation(HelperLocationUpdateEvent event) {
    setState(() {
      _latest = event;
    });
    // Persist for the next session so a cold start (or a SignalR
    // drop) still has *some* helper position to render until the
    // next live tick lands.
    _persistLatestLocation(event);
    // Smoothly follow the helper pin as it moves.
    _mapboxMap?.setCamera(CameraOptions(
      center: Point(coordinates: Position(event.longitude, event.latitude)),
      zoom: 16,
    ));
    _updateHelperPin(event.latitude, event.longitude);

    // Refresh the polyline at most every 10 s. The polyline now
    // tracks where the helper is *actually heading*: to the pickup
    // point pre-trip, to the destination once they hit `/start`.
    // Without this phase split, the line was always going from the
    // helper's current spot to the destination — even when the
    // helper hadn't picked the user up yet — which made the route
    // visually wrong by tens of kilometres in city scenarios.
    if (!_routeRefreshAllowed) return;
    _routeRefreshAllowed = false;
    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(seconds: 10), () {
      _routeRefreshAllowed = true;
    });
    _refreshHelperRoute(event);
  }

  /// Fetches a fresh road-following polyline from the helper's
  /// current position to the next waypoint based on the trip phase.
  Future<void> _refreshHelperRoute(HelperLocationUpdateEvent event) async {
    final booking = _bookingFrom(widget.cubit.state);
    if (booking == null) return;
    // Phase semantics (per backend, 2026-05-09):
    //   - "OnTheWay" (or anything pre-`/start`) → helper en route to
    //     pickup, so the line should run helper → pickup.
    //   - "InProgress" → user is on board, line should run helper →
    //     destination.
    final isOnTrip = event.phase == 'InProgress';
    final toLat = isOnTrip
        ? booking.destinationLatitude
        : booking.pickupLatitude;
    final toLng = isOnTrip
        ? booking.destinationLongitude
        : booking.pickupLongitude;
    if (toLat == null || toLng == null) return;
    await _fetchAndDrawPolyline(
      fromLat: event.latitude,
      fromLng: event.longitude,
      toLat: toLat,
      toLng: toLng,
    );
  }

  Future<void> _updateHelperPin(double lat, double lng) async {
    if (_markerManager == null) return;
    _helperMarkerPng ??= await MapMarkers.helperDot();
    if (!mounted || _markerManager == null) return;
    if (_helperPin != null) {
      try {
        await _markerManager!.delete(_helperPin!);
      } catch (_) {}
    }
    _helperPin = await _markerManager!.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(lng, lat)),
      image: _helperMarkerPng,
      iconAnchor: IconAnchor.CENTER,
    ));
  }

  void _onTripEnded(BookingTripEndedEvent event) {
    if (!mounted) return;
    setState(() {
      _tripEnded = true;
    });
    // Clean up the cached snapshot so a future booking with the
    // same id can't reuse a stale marker.
    LastHelperLocationStore.instance.clear(widget.bookingId);
    unawaited(sl<PendingRatingTracker>().markPending(widget.bookingId));
    if (widget.cubit.selectedPaymentMethod == AppPaymentMethod.mockCard) {
      context.go(AppRouter.bookingHome);
      return;
    }
    context.go(
      AppRouter.instantPayNow.replaceFirst(':id', widget.bookingId),
      extra: {'cubit': widget.cubit, 'requireRating': true},
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
    LastHelperLocationStore.instance.clear(widget.bookingId);
    if (!context.mounted) return;
    context.go(AppRouter.bookingHome);
  }

  Future<void> _callHelper(String? phone) async {
    final p = (phone ?? '').trim();
    if (p.isEmpty) return;
    HapticFeedback.selectionClick();
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
    HapticFeedback.selectionClick();
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support has been alerted')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS cancelled')),
      );
      return;
    }
    setState(() {
      _cancelingSos = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(result.message ?? 'Could not cancel SOS. Please retry.'),
      ),
    );
  }

  void _recenter() {
    HapticFeedback.selectionClick();
    if (_latest != null) {
      _mapboxMap?.setCamera(CameraOptions(
        center: Point(
          coordinates:
              Position(_latest!.longitude, _latest!.latitude),
        ),
        zoom: 16,
      ));
    }
  }

  /// Pops the OS-native share sheet (Android `ACTION_SEND` /
  /// iOS `UIActivityViewController`) with a friendly text payload
  /// containing the helper name, ETA, pickup and destination, plus
  /// a deep-link the recipient can open back into the app.
  ///
  /// We deliberately avoid backend integrations / tokens — the
  /// payload is plain text so it works in WhatsApp, SMS, Telegram,
  /// email, anything. When a public read-only tracking URL exists
  /// on the backend we'll swap [trackingUrl] in here.
  Future<void> _shareTrip() async {
    HapticFeedback.selectionClick();
    final booking = _bookingFrom(widget.cubit.state);
    final helperName = widget.helper?.fullName ??
        booking?.helper?.fullName ??
        'my helper';
    final pickup = booking?.pickupAddress ?? 'pickup point';
    final destination = booking?.destinationName ?? 'my destination';
    final eta = _latest?.etaToPickupMinutes ??
        _latest?.etaToDestinationMinutes ??
        _primedSnapshot?.etaToPickupMinutes ??
        _primedSnapshot?.etaToDestinationMinutes;
    final etaLine = eta != null ? '\nETA: $eta min' : '';
    // Universal link / custom scheme back into the app. If your
    // app links table doesn't include this path yet that's fine —
    // the share text remains useful as plain prose.
    final trackingUrl = 'https://rafiq.app/track/${widget.bookingId}';
    final message = StringBuffer()
      ..writeln("I'm on my way — sharing my Rafiq trip with you!")
      ..writeln()
      ..writeln('Helper: $helperName')
      ..writeln('From: $pickup')
      ..writeln('To: $destination')
      ..write(etaLine.isNotEmpty ? etaLine : '')
      ..writeln()
      ..writeln()
      ..writeln('Track me live: $trackingUrl');
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: message.toString(),
          subject: 'My Rafiq trip',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open share sheet: $e')),
      );
    }
  }

  /// Maps `BookingStatus` + the raw `HelperLocationUpdate.phase`
  /// string into the small enum the UI uses.
  ///
  /// Backend confirmed (PR review, 2026-05-09) that:
  ///   • Tracking broadcasts start the moment the helper accepts —
  ///     so `AcceptedByHelper` already produces real GPS samples.
  ///   • The `phase` field on each event is exactly one of two
  ///     strings: `"OnTheWay"` (pre-`/start`) or `"InProgress"`
  ///     (post-`/start`). There is no `"ToPickup"` / `"ToDestination"`.
  ///
  /// Mapping below:
  ///   • status == `AcceptedByHelper` / `ConfirmedAwaitingPayment` /
  ///     `ConfirmedPaid` / `Upcoming` → `toPickup` (helper en route to
  ///     pickup, ETA-to-pickup is the meaningful figure).
  ///   • status == `InProgress` → `toDestination` (user is on board).
  ///   • Anything else (terminal / cancelled) → `ended`.
  ///
  /// `awaitingGps` covers the brief gap between "we know the booking
  /// is live" and "we've received our first sample" — keeps the UI
  /// from showing a confusing `-- min` while the realtime stream
  /// warms up.
  _TripPhase _derivePhase({
    required BookingDetail? booking,
    required bool hasGps,
    required String? rawPhase,
  }) {
    if (_tripEnded) return _TripPhase.ended;
    final status = booking?.status;
    if (status == null) {
      // Booking not hydrated yet — show calm pre-start UX.
      return _TripPhase.preStart;
    }
    final isAccepted = status == BookingStatus.acceptedByHelper ||
        status == BookingStatus.confirmedAwaitingPayment ||
        status == BookingStatus.confirmedPaid ||
        status == BookingStatus.upcoming;
    final isInProgress = status == BookingStatus.inProgress;
    if (!isAccepted && !isInProgress) {
      return _TripPhase.ended;
    }
    if (!hasGps) {
      // We're in a tracking-eligible status but no sample has
      // landed yet (or the helper hasn't moved past the throttle
      // window) — distinct from `preStart` so the UI can show a
      // "connecting" hint instead of a static "Heading your way".
      return _TripPhase.awaitingGps;
    }
    // hasGps == true: we know the helper's location. Use the raw
    // phase string (the only authoritative phase signal — backend
    // sends `InProgress` once the trip starts, `OnTheWay` otherwise).
    if (rawPhase == 'InProgress') {
      return _TripPhase.toDestination;
    }
    // Anything else (`OnTheWay`, null, unknown legacy value) ⇒
    // helper still heading to the pickup point.
    return _TripPhase.toPickup;
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
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Color(0xFFFFFFFF),
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            // The map fills the entire screen — extend behind the
            // status bar so the system bar gets a transparent overlay
            // instead of the dark default Android draws when a
            // Scaffold body doesn't reach the top of the device.
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: const Color(0xFFFBF8FF),
            body: BlocBuilder<InstantBookingCubit, InstantBookingState>(
              builder: (context, state) {
                final booking = _bookingFrom(state);
                if (booking != null) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _drawRoute(booking));
                }
                final helperName = widget.helper?.fullName ??
                    booking?.helper?.fullName ??
                    'Your helper';
                final helperFirstName = helperName.split(' ').first;
                final helperImage = widget.helper?.profileImageUrl ??
                    booking?.helper?.profileImageUrl;
                final phone = booking?.helper?.phoneNumber;
                // ETA pick: live stream first, then server snapshot.
                //
                // Backend phase field (confirmed): exactly two strings,
                // `"OnTheWay"` (helper en route to pickup) or
                // `"InProgress"` (post-/start, heading to destination).
                final activePhase = _latest?.phase ?? _primedSnapshot?.phase;
                int? etaMinutes;
                if (activePhase == 'InProgress') {
                  etaMinutes = _latest?.etaToDestinationMinutes ??
                      _primedSnapshot?.etaToDestinationMinutes;
                } else {
                  // `"OnTheWay"`, null, or any unknown phase → use
                  // ETA-to-pickup which is what's meaningful before
                  // the trip starts.
                  etaMinutes = _latest?.etaToPickupMinutes ??
                      _primedSnapshot?.etaToPickupMinutes;
                }
                final tripPhase = _derivePhase(
                  booking: booking,
                  hasGps: _latest != null || _primedSnapshot != null,
                  rawPhase: activePhase,
                );
                return Stack(
                  children: [
                    // Map.
                    MapWidget(
                      key: const ValueKey('tripTrackingMap'),
                      // ignore: deprecated_member_use
                      cameraOptions: CameraOptions(
                        center: Point(
                          coordinates: Position(
                            booking?.pickupLongitude ??
                                (_latest?.longitude ?? 0),
                            booking?.pickupLatitude ??
                                (_latest?.latitude ?? 0),
                          ),
                        ),
                        zoom: booking == null ? 3.0 : 15.0,
                      ),
                      styleUri: MapboxStyles.LIGHT,
                      onMapCreated: _onMapCreated,
                    ),
                    // Floating top status pill.
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 12,
                      // Leave the left third clear for the back
                      // button. The pill self-aligns to the right
                      // half of the available room.
                      left: 76,
                      right: 16,
                      child: Align(
                        alignment: Alignment.center,
                        child: _StatusPill(
                          name: helperFirstName.isEmpty
                              ? 'Helper'
                              : helperFirstName,
                          etaMinutes: etaMinutes,
                          fallback: _lastRoute?.durationLabel,
                          phase: tripPhase,
                          sampleAgeSeconds: _sampleAgeSeconds(),
                        ),
                      ),
                    ),
                    // Top-left back button. We deliberately do NOT
                    // pass a tooltip — Android renders tooltips on
                    // long-press as a dark grey label that lingers
                    // and visually overlaps the floating button.
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 12,
                      left: 16,
                      child: _RoundButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.go(AppRouter.home),
                        background: Colors.white,
                        iconColor: BrandTokens.primaryBlue,
                      ),
                    ),
                    // Right side floating actions.
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            UnreadChatBadge(
                              bookingId: widget.bookingId,
                              offset: const Offset(2, -2),
                              child: _RoundButton(
                                icon: Icons.chat_bubble_outline_rounded,
                                onTap: _openChat,
                                background: Colors.white,
                                iconColor: BrandTokens.primaryBlue,
                                size: 56,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (!_tripEnded)
                              _RoundButton(
                                icon: Icons.emergency_rounded,
                                onTap: _openSosSheet,
                                background: Colors.white,
                                iconColor: BrandTokens.dangerRed,
                                size: 56,
                              ),
                            const SizedBox(height: 16),
                            _RoundButton(
                              icon: Icons.my_location_rounded,
                              onTap: _recenter,
                              background: Colors.white,
                              iconColor: BrandTokens.textSecondary,
                              size: 48,
                            ),
                          ],
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
                    const Positioned(
                      right: 6,
                      bottom: 6,
                      child: _OsmAttribution(),
                    ),
                    // Bottom sheet (driver card with progress bar).
                    DraggableScrollableSheet(
                      initialChildSize: 0.42,
                      minChildSize: 0.24,
                      maxChildSize: 0.74,
                      builder: (context, scrollController) {
                        return _TrackingSheet(
                          scrollController: scrollController,
                          latest: _latest,
                          primedSnapshot: _primedSnapshot,
                          booking: booking,
                          route: _lastRoute,
                          helperImageUrl: helperImage,
                          helperName: helperName,
                          phone: phone,
                          phaseUi: tripPhase,
                          onCall: () => _callHelper(phone),
                          onChat: _openChat,
                          onShareTrip: _shareTrip,
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
      ),
    );
  }

  BookingDetail? _bookingFrom(InstantBookingState s) {
    if (s is InstantBookingAccepted) return s.booking;
    if (s is InstantBookingWaiting) return s.booking;
    return null;
  }

  /// Seconds since the freshest helper sample landed (live stream,
  /// REST prime, or persistent cache — whichever is most recent).
  /// Returns `null` when we have no data at all so the UI can fall
  /// back to a calm "Heading your way" instead of "last seen 0 min".
  int? _sampleAgeSeconds() {
    DateTime? captured;
    if (_latest?.capturedAt != null) {
      captured = _latest!.capturedAt;
    } else if (_primedSnapshot != null) {
      captured = _primedSnapshot!.timestamp;
    } else if (_persistedLast != null) {
      captured = _persistedLast!.capturedAt;
    }
    if (captured == null) return null;
    return DateTime.now().toUtc().difference(captured.toUtc()).inSeconds;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status pill — top-centre floating helper-name + ETA strip.
// ─────────────────────────────────────────────────────────────────────────────

/// Coarse trip phase the UI cares about. The map page derives this
/// from `booking.status` + the live SignalR phase string so every
/// status-aware widget has a single source of truth.
enum _TripPhase {
  /// Helper accepted but hasn't started the trip yet — no GPS yet.
  preStart,

  /// Trip is in progress, helper still hasn't shared GPS.
  awaitingGps,

  /// Helper is moving toward the pickup point.
  toPickup,

  /// Helper has the user on board and is heading to destination.
  toDestination,

  /// Trip ended (or unknown / cancelled — fall through to a calm state).
  ended,
}

class _StatusPill extends StatelessWidget {
  final String name;
  final int? etaMinutes;
  final String? fallback;
  final _TripPhase phase;
  /// Seconds since the freshest helper sample was captured. When
  /// large (>= 90 s) the pill switches into "Last seen N min ago"
  /// mode so the user knows GPS dropped instead of staring at a
  /// stale ETA.
  final int? sampleAgeSeconds;
  const _StatusPill({
    required this.name,
    required this.etaMinutes,
    required this.fallback,
    required this.phase,
    required this.sampleAgeSeconds,
  });

  String _statusText(BuildContext context) {
    final age = sampleAgeSeconds ?? 0;
    final isStale = age >= 90;
    if (isStale) {
      final minutesAgo = (age / 60).round();
      if (minutesAgo <= 0) return 'last seen just now';
      return 'last seen ${context.localizeNumber(minutesAgo)} min ago';
    }
    if (etaMinutes != null) {
      return '${context.localizeNumber(etaMinutes!)} min away';
    }
    if (fallback != null) return '$fallback away';
    switch (phase) {
      case _TripPhase.preStart:
        return 'Heading your way';
      case _TripPhase.awaitingGps:
        return 'Connecting GPS…';
      case _TripPhase.toPickup:
        return 'On the way';
      case _TripPhase.toDestination:
        return 'On the road';
      case _TripPhase.ended:
        return 'Trip ended';
    }
  }

  @override
  Widget build(BuildContext context) {
    final etaText = _statusText(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 140,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PulsingDot(),
            const SizedBox(width: 10),
            Flexible(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1B1B21),
                  ),
                  children: [
                    TextSpan(
                      text: name,
                      style: const TextStyle(
                        color: BrandTokens.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: '  ·  '),
                    TextSpan(text: etaText),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFFFE9331),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFE9331).withValues(alpha: 0.45 * (1 - t)),
                blurRadius: 4 + 6 * t,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Round white floating button (chat / SOS / recenter / back).
// ─────────────────────────────────────────────────────────────────────────────

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color iconColor;
  final double size;
  const _RoundButton({
    required this.icon,
    required this.onTap,
    required this.background,
    required this.iconColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            boxShadow: [
              BoxShadow(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: iconColor, size: size * 0.46),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OSM attribution — required by the tile usage policy.
// ─────────────────────────────────────────────────────────────────────────────

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
        '\u00A9 OpenStreetMap contributors',
        style: TextStyle(fontSize: 10, color: Colors.black87),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom tracking sheet (driver card + progress bar + Share/Contact).
// ─────────────────────────────────────────────────────────────────────────────

class _TrackingSheet extends StatelessWidget {
  final ScrollController scrollController;
  final HelperLocationUpdateEvent? latest;

  /// Server-side `/tracking/latest` snapshot — used when the live
  /// stream hasn't delivered its first sample yet so the ETA card
  /// and progress bar still have something meaningful to show.
  final TrackingPointEntity? primedSnapshot;
  final BookingDetail? booking;
  final RouteResult? route;
  final String? helperImageUrl;
  final String helperName;
  final String? phone;
  final _TripPhase phaseUi;
  final VoidCallback onCall;
  final VoidCallback onChat;
  final VoidCallback onShareTrip;
  final VoidCallback? onCancel;

  const _TrackingSheet({
    required this.scrollController,
    required this.latest,
    required this.primedSnapshot,
    required this.booking,
    required this.route,
    required this.helperImageUrl,
    required this.helperName,
    required this.phone,
    required this.phaseUi,
    required this.onCall,
    required this.onChat,
    required this.onShareTrip,
    required this.onCancel,
  });

  double? get _dPick =>
      latest?.distanceToPickupKm ?? primedSnapshot?.distanceToPickupKm;
  double? get _dDest =>
      latest?.distanceToDestinationKm ??
      primedSnapshot?.distanceToDestinationKm;

  /// 0 → at pickup, 1 → at destination. The progress bar is built
  /// around the live ride: pre-trip → 0%, on-the-way-to-pickup → 0..50%,
  /// on-the-way-to-destination → 50..100%, ended → 100%.
  double _progress() {
    switch (phaseUi) {
      case _TripPhase.preStart:
      case _TripPhase.awaitingGps:
        return 0.0;
      case _TripPhase.toPickup:
        final dPick = _dPick ?? 0;
        if (dPick <= 0) return 0.5;
        return (1 - (dPick / (dPick + 1)).clamp(0.0, 1.0)) * 0.5;
      case _TripPhase.toDestination:
        final dDest = _dDest ?? 0;
        if (dDest <= 0) return 1.0;
        return 0.5 + (1 - (dDest / (dDest + 1)).clamp(0.0, 1.0)) * 0.5;
      case _TripPhase.ended:
        return 1.0;
    }
  }

  String get _statusSubtitle {
    switch (phaseUi) {
      case _TripPhase.preStart:
        return 'Preparing for pickup';
      case _TripPhase.awaitingGps:
        return 'Connecting GPS…';
      case _TripPhase.toPickup:
        return 'On the way to pickup';
      case _TripPhase.toDestination:
        return 'Heading to destination';
      case _TripPhase.ended:
        return 'Trip ended';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDestPhase = phaseUi == _TripPhase.toDestination;
    final eta = isDestPhase
        ? (latest?.etaToDestinationMinutes ??
            primedSnapshot?.etaToDestinationMinutes)
        : (latest?.etaToPickupMinutes ??
            primedSnapshot?.etaToPickupMinutes);
    final pickupName = booking?.pickupLocationName ?? 'Pickup';
    final destinationName = booking?.destinationName ?? 'Destination';
    final progress = _progress();
    final rating = booking?.helper?.rating;
    final ratingText = rating != null && rating > 0
        ? context.localizeNumber(rating, decimals: 1)
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x141B237E),
            blurRadius: 50,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFC6C5D4),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _HelperInfoEtaRow(
            helperName: helperName,
            helperImageUrl: helperImageUrl,
            ratingText: ratingText,
            statusSubtitle: _statusSubtitle,
            etaMinutes: eta,
            phaseUi: phaseUi,
          ),
          const SizedBox(height: 22),
          _ProgressBar(progress: progress),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  pickupName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF767683),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  destinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF767683),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Action row — matches the mockup: gray "Share Trip" pill on
          // the left + filled primary "Contact {Name}" pill on the
          // right. Contact opens the dialer when we have a phone, or
          // falls back to the chat (so the button is never useless).
          Row(
            children: [
              Expanded(
                child: _SheetActionButton(
                  label: 'Share Trip',
                  variant: _SheetActionVariant.tonal,
                  onTap: onShareTrip,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetActionButton(
                  label: 'Contact ${helperName.split(' ').first}',
                  variant: _SheetActionVariant.filled,
                  onTap: (phone ?? '').isNotEmpty ? onCall : onChat,
                ),
              ),
            ],
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: BrandTokens.dangerRed,
                ),
                child: const Text(
                  'Cancel trip',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// First row of the bottom sheet — avatar + name + rating + status
/// subtitle on the left, and a big `ARRIVING IN  N min` block on
/// the right. The right block degrades gracefully into a calmer
/// label when no ETA is known yet (pre-trip / awaiting GPS).
class _HelperInfoEtaRow extends StatelessWidget {
  final String helperName;
  final String? helperImageUrl;
  final String? ratingText;
  final String statusSubtitle;
  final int? etaMinutes;
  final _TripPhase phaseUi;

  const _HelperInfoEtaRow({
    required this.helperName,
    required this.helperImageUrl,
    required this.ratingText,
    required this.statusSubtitle,
    required this.etaMinutes,
    required this.phaseUi,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: AppNetworkImage(
              imageUrl: helperImageUrl,
              width: 60,
              height: 60,
              borderRadius: 30,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                helperName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BrandTokens.heading(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: BrandTokens.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Color(0xFFFE9331),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      ratingText != null
                          ? '$ratingText  ·  $statusSubtitle'
                          : statusSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF767683),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _EtaBlock(etaMinutes: etaMinutes, phaseUi: phaseUi),
      ],
    );
  }
}

class _EtaBlock extends StatelessWidget {
  final int? etaMinutes;
  final _TripPhase phaseUi;
  const _EtaBlock({required this.etaMinutes, required this.phaseUi});

  @override
  Widget build(BuildContext context) {
    final hasEta = etaMinutes != null;
    if (!hasEta) {
      // No ETA yet — render a calm "Awaiting GPS" / "Heading your way"
      // label instead of a dashed `-- min`.
      final label = phaseUi == _TripPhase.preStart
          ? 'HEADING\nYOUR WAY'
          : 'AWAITING\nGPS';
      return SizedBox(
        width: 96,
        child: Text(
          label,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: BrandTokens.primaryBlue.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.25,
            letterSpacing: 1.0,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'ARRIVING IN',
          style: TextStyle(
            color: Color(0xFF767683),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: context.localizeNumber(etaMinutes!),
                style: BrandTokens.heading(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: BrandTokens.primaryBlue,
                  letterSpacing: -1.5,
                  height: 1.0,
                ),
              ),
              TextSpan(
                text: ' min',
                style: BrandTokens.heading(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: BrandTokens.primaryBlue.withValues(
                    alpha: 0.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  /// 0..1 — current trip progress.
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: Color(0xFFEAE7EF)),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BrandTokens.primaryBlue,
                      BrandTokens.primaryBlue.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SheetActionVariant { tonal, filled }

class _SheetActionButton extends StatelessWidget {
  final String label;
  final _SheetActionVariant variant;
  final VoidCallback onTap;
  const _SheetActionButton({
    required this.label,
    required this.variant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = variant == _SheetActionVariant.filled;
    // Tonal = soft warm-grey surface (#F5F2FB) with primary-blue text.
    // Filled = solid primary blue with white text + subtle blue
    // shadow for the strong contrast in the mockup.
    final bg = isFilled ? BrandTokens.primaryBlue : const Color(0xFFF5F2FB);
    final fg = isFilled ? Colors.white : BrandTokens.primaryBlue;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(40),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(40),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: BrandTokens.primaryBlue.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
