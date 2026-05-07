import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/helper/features/helper_bookings/presentation/cubit/trip_action_cubit.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../../../helper_chat/presentation/pages/helper_chat_page.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../helper_ratings/presentation/pages/rate_user_page.dart';
import '../../../helper_location/presentation/cubit/helper_location_cubit.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../../../../core/services/location/mapbox_directions_service.dart';
import '../../../helper_booking_tracking/domain/usecases/get_latest_location_usecase.dart'
    as helper_track;
import '../../../helper_booking_tracking/domain/usecases/get_tracking_history_usecase.dart'
    as helper_track;
import '../../../helper_location/domain/usecases/helper_location_usecases.dart'
    as helper_location;
import 'package:toury/core/models/tracking/tracking_point_entity.dart';
import '../../../helper_sos/presentation/widgets/helper_sos_floating_button.dart';
import '../../../helper_sos/presentation/widgets/helper_sos_sheet.dart';
import '../../../helper_sos/presentation/cubit/helper_sos_cubit.dart';
import '../../../helper_sos/presentation/widgets/helper_sos_active_banner.dart';
import '../widgets/active/active_booking_components.dart';

class ActiveBookingPage extends StatefulWidget {
  final String bookingId;
  const ActiveBookingPage({super.key, required this.bookingId});

  @override
  State<ActiveBookingPage> createState() => _ActiveBookingPageState();
}

class _ActiveBookingPageState extends State<ActiveBookingPage> {
  late final ActiveBookingCubit _activeCubit;
  late final TripActionCubit _tripActionCubit;
  late final HelperLocationCubit _locationCubit;
  late final HelperSosCubit _sosCubit;
  late final AuthService _authService;
  late final helper_track.GetLatestLocationUseCase _getLatestTracking;
  late final helper_track.GetTrackingHistoryUseCase _getTrackingHistory;
  late final helper_location.GetLocationStatusUseCase _getLocationStatus;
  final _directions = MapboxDirectionsService();
  MapboxMap? _mapboxMap;
  // Manager for pickup/destination pins (gets cleared on route updates).
  PointAnnotationManager? _pointAnnotationManager;
  // Dedicated manager for the helper's live marker so it doesn't get wiped
  // when the route is redrawn.
  PointAnnotationManager? _helperPointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  PointAnnotation? _helperMarker;
  HelperBooking? _currentBooking;
  RouteResult? _lastRoute; // cached for the info chip
  bool _isFollowing = true;
  bool _isNavigationMode = false;
  Timer? _routeDebounce;   // throttle real-time updates to 1 call / 10 s
  bool _isRouteFetchInFlight = false;
  DateTime? _lastRouteFetchAt;
  double? _lastRouteFromLat;
  double? _lastRouteFromLng;
  String? _lastRouteMode; // to_pickup | to_destination
  double? _helperLat;
  double? _helperLng;
  List<TrackingPointEntity> _trackingHistory = const [];
  bool _hasArrivedAtPickup = false;
  bool _didPrimeTracking = false;
  static const double _pickupArrivalThresholdMeters = 120;

  @override
  void initState() {
    super.initState();
    _activeCubit = sl<ActiveBookingCubit>();
    _tripActionCubit = sl<TripActionCubit>();
    _locationCubit = sl<HelperLocationCubit>();
    _sosCubit = sl<HelperSosCubit>();
    _authService = sl<AuthService>();
    _getLatestTracking = sl<helper_track.GetLatestLocationUseCase>();
    _getTrackingHistory = sl<helper_track.GetTrackingHistoryUseCase>();
    _getLocationStatus = sl<helper_location.GetLocationStatusUseCase>();
    
    // Start trip tracking if we have an ID
    if (widget.bookingId.isNotEmpty) {
      _didPrimeTracking = true;
      _primeTrackingFromApi(widget.bookingId);
      final token = _authService.getToken();
      if (token != null) {
        _locationCubit.startTripTracking(token, widget.bookingId);
      }
      _activeCubit.loadById(widget.bookingId);
    } else {
      _activeCubit.load();
    }
  }

  @override
  void dispose() {
    _routeDebounce?.cancel();
    _helperMarker = null;
    _helperPointAnnotationManager = null;
    _pointAnnotationManager = null;
    _polylineAnnotationManager = null;
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    // Reduce extra native view/plugin work on older Android devices.
    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    mapboxMap.logo.updateSettings(LogoSettings(enabled: false));
    mapboxMap.attribution.updateSettings(AttributionSettings(enabled: false));
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    _polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();
    // Create the helper marker manager LAST so it renders on top of pins/lines.
    _helperPointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    if (_helperLat != null && _helperLng != null) {
      unawaited(_updateHelperMarker(_helperLat!, _helperLng!));
    }

    if (_currentBooking != null) {
      _drawRoute(_currentBooking!);
    }
  }

  void _recenter(double lat, double lng) {
    _mapboxMap?.setCamera(CameraOptions(
      center: Point(coordinates: Position(lng, lat)),
      zoom: 15,
    ));
  }

  void _recenterNavigation(double lat, double lng, {double? heading}) {
    _mapboxMap?.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: 17.2,
        pitch: 52,
        bearing: (heading != null && heading.isFinite) ? heading : null,
      ),
    );
  }

  // ── Route drawing ───────────────────────────────────────────────────────

  /// Initial draw: route from pickup → destination using Directions API.
  void _drawRoute(HelperBooking booking) async {
    final isStarted = _isTripStarted(booking);
    final fromLat = _helperLat ?? booking.pickupLat;
    final fromLng = _helperLng ?? booking.pickupLng;
    final toLat = isStarted ? booking.destinationLat : booking.pickupLat;
    final toLng = isStarted ? booking.destinationLng : booking.pickupLng;
    await _fetchAndDrawRoute(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      booking: booking,
    );
  }

  /// Called when the helper's GPS updates — re-routes dynamically by trip stage.
  void _onHelperLocationForRoute(double helperLat, double helperLng) {
    final booking = _currentBooking;
    if (booking == null) return;
    final isStarted = _isTripStarted(booking);
    final mode = isStarted ? 'to_destination' : 'to_pickup';
    final targetLat = isStarted ? booking.destinationLat : booking.pickupLat;
    final targetLng = isStarted ? booking.destinationLng : booking.pickupLng;
    if (!_shouldFetchRoute(helperLat, helperLng, mode)) return;
    // Debounce: only re-fetch every 20 seconds to reduce UI/load spikes.
    if (_routeDebounce?.isActive == true) return;
    _routeDebounce = Timer(const Duration(seconds: 20), () {});
    _fetchAndDrawRoute(
      fromLat: helperLat,
      fromLng: helperLng,
      toLat: targetLat,
      toLng: targetLng,
      booking: booking,
    );
  }

  Future<void> _fetchAndDrawRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required HelperBooking booking,
  }) async {
    if (_pointAnnotationManager == null || _polylineAnnotationManager == null) return;
    if (_isRouteFetchInFlight) return;
    _isRouteFetchInFlight = true;

    try {
      await _pointAnnotationManager!.deleteAll();
      await _polylineAnnotationManager!.deleteAll();

      // Draw pickup & destination pins.
      await _pointAnnotationManager!.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(booking.pickupLng, booking.pickupLat)),
        iconImage: 'marker-15',
        textField: 'Pickup',
        textOffset: [0.0, -2.5],
      ));
      await _pointAnnotationManager!.create(PointAnnotationOptions(
        geometry:
            Point(coordinates: Position(booking.destinationLng, booking.destinationLat)),
        iconImage: 'marker-15',
        textField: 'Destination',
        textOffset: [0.0, -2.5],
      ));
      // Fetch real road route.
      final route = await _directions.getRoute(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
        profile: 'driving',
      );

      if (route == null || route.coordinates.isEmpty) {
        // Fallback: straight line so the map still shows something.
        await _polylineAnnotationManager!.create(PolylineAnnotationOptions(
          geometry: LineString(coordinates: [
            Position(fromLng, fromLat),
            Position(toLng, toLat),
          ]),
          lineColor: BrandTokens.primaryBlue.toARGB32(),
          lineWidth: 3.5,
          lineOpacity: 0.6,
        ));
        await _drawHistoryPolyline();
        return;
      }

      // Cache for the distance/duration chip.
      if (mounted) setState(() => _lastRoute = route);

      // Convert [[lng, lat], ...] → Mapbox Position list.
      final positions = route.coordinates.map((c) => Position(c[0], c[1])).toList();

      await _polylineAnnotationManager!.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: positions),
        lineColor: BrandTokens.primaryBlue.toARGB32(),
        lineWidth: 5.0,
        lineOpacity: 0.85,
      ));
      await _drawHistoryPolyline();
      _lastRouteFetchAt = DateTime.now();
      _lastRouteFromLat = fromLat;
      _lastRouteFromLng = fromLng;
    } finally {
      _isRouteFetchInFlight = false;
    }
  }

  Future<void> _drawHistoryPolyline() async {
    if (_polylineAnnotationManager == null || _trackingHistory.length < 2) return;
    final historyPositions = _trackingHistory
        .map((p) => Position(p.longitude, p.latitude))
        .toList();
    await _polylineAnnotationManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: historyPositions),
        lineColor: BrandTokens.textMuted.toARGB32(),
        lineWidth: 3.0,
        lineOpacity: 0.45,
      ),
    );
  }

  Future<void> _primeTrackingFromApi(String bookingId) async {
    var seededFromTracking = false;
    final latestResult = await _getLatestTracking(bookingId);
    latestResult.fold((_) {}, (latest) {
      _helperLat = latest.latitude;
      _helperLng = latest.longitude;
      seededFromTracking = true;
    });

    final historyResult = await _getTrackingHistory(bookingId);
    historyResult.fold((_) {}, (history) {
      _trackingHistory = history;
    });
    if (!seededFromTracking && _helperLat == null && _helperLng == null) {
      // Fallback seed for brand-new trips where tracking has no samples yet.
      try {
        final status = await _getLocationStatus.execute();
        if (status.currentLatitude != null && status.currentLongitude != null) {
          _helperLat = status.currentLatitude;
          _helperLng = status.currentLongitude;
        }
      } catch (_) {}
    }

    if (_currentBooking != null && _helperLat != null && _helperLng != null) {
      final arrived = _distanceMeters(
            _helperLat!,
            _helperLng!,
            _currentBooking!.pickupLat,
            _currentBooking!.pickupLng,
          ) <=
          _pickupArrivalThresholdMeters;
      if (mounted) {
        setState(() {
          _hasArrivedAtPickup = arrived;
        });
      }
    }
    if (_mapboxMap != null && _currentBooking != null) {
      _drawRoute(_currentBooking!);
    }
  }

  bool _shouldFetchRoute(double fromLat, double fromLng, String mode) {
    if (_lastRouteMode != mode) {
      _lastRouteMode = mode;
      return true;
    }
    if (_lastRouteFetchAt == null || _lastRouteFromLat == null || _lastRouteFromLng == null) {
      return true;
    }
    final movedMeters = _distanceMeters(
      fromLat,
      fromLng,
      _lastRouteFromLat!,
      _lastRouteFromLng!,
    );
    return movedMeters >= 35;
  }

  Future<void> _updateHelperMarker(
    double lat,
    double lng, {
    double? heading,
  }) async {
    // Use the dedicated helper marker manager so route redraws (which call
    // deleteAll on the pins manager) never wipe the live arrow.
    final manager = _helperPointAnnotationManager;
    if (manager == null) return;
    if (_helperMarker != null) {
      try {
        await manager.delete(_helperMarker!);
      } catch (_) {}
      _helperMarker = null;
    }
    final normalizedHeading =
        (heading != null && heading.isFinite) ? heading : 0.0;
    try {
      _helperMarker = await manager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          iconImage: 'triangle-15',
          iconSize: 2.4,
          iconRotate: normalizedHeading,
          symbolSortKey: 9999,
        ),
      );
    } catch (_) {
      // Fallback if style sprite doesn't include triangle icon.
      try {
        _helperMarker = await manager.create(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(lng, lat)),
            iconImage: 'embassy-15',
            iconSize: 2.1,
            textField: 'You',
            textColor: BrandTokens.primaryBlue.toARGB32(),
            textOffset: [0.0, -2.2],
            symbolSortKey: 9999,
          ),
        );
      } catch (_) {
        _helperMarker = null;
      }
    }
  }

  bool _isTripStarted(HelperBooking booking) {
    // Some helper endpoints don't always include a reliable status after start.
    // `canEndTrip` is a strong signal that the trip is already in progress.
    if (booking.canEndTrip) return true;
    final s = booking.status.toLowerCase();
    return s == 'inprogress' || s == 'started' || s == 'active';
  }

  double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _activeCubit),
        BlocProvider.value(value: _tripActionCubit),
        BlocProvider.value(value: _locationCubit),
        BlocProvider.value(value: _sosCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<TripActionCubit, TripActionState>(
            listener: (context, state) {
              if (state is TripActionSuccess) {
                if (state.actionType == 'start') {
                  _showSnack(context, '🚀 Trip started!');
                  setState(() => _isNavigationMode = true);
                  _activeCubit.load();
                } else if (state.actionType == 'end') {
                  final earnings = state.result as double? ?? 0.0;
                  final booking = _currentBooking;
                  _showEarningsDialog(context, earnings, onDismiss: () {
                    if (booking != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RateUserPage(
                            bookingId: booking.id,
                            travelerName: booking.travelerName,
                            travelerAvatar: booking.travelerImage ?? '',
                          ),
                        ),
                      ).then((_) {
                        if (!mounted) return;
                        _completeTripAndExit();
                      });
                    } else {
                      _completeTripAndExit();
                    }
                  });
                }
              } else if (state is TripActionError) {
                _showSnack(context, state.message, isError: true);
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: BlocBuilder<ActiveBookingCubit, ActiveBookingState>(
            builder: (context, state) {
              if (state is ActiveBookingLoading) {
                return const Center(
                    child: CircularProgressIndicator(color: BrandTokens.primaryBlue));
              }
              if (state is ActiveBookingLoaded && state.booking != null) {
                _currentBooking = state.booking;
                if (!_didPrimeTracking) {
                  _didPrimeTracking = true;
                  unawaited(_primeTrackingFromApi(state.booking!.id));
                }
                return _buildModernContent(context, state.booking!);
              }
              return _buildNoTrip(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModernContent(BuildContext context, HelperBooking booking) {
    final status = booking.status.toLowerCase();
    final isStarted = _isTripStarted(booking);
    final navMode = _isNavigationMode || isStarted;
    
    final initialCenter = isStarted
        ? Position(booking.destinationLng, booking.destinationLat)
        : Position(booking.pickupLng, booking.pickupLat);

    return Stack(
      children: [
        // 1. Full Screen Map
        MapWidget(
          key: const ValueKey("activeBookingMap"),
          cameraOptions: CameraOptions(
            center: Point(coordinates: initialCenter),
            zoom: 15.0,
          ),
          styleUri: MapboxStyles.LIGHT,
          onMapCreated: _onMapCreated,
        ),

        // Helper Location Logic (UI-less BlocBuilder to handle camera movement)
        BlocListener<HelperLocationCubit, HelperLocationState>(
          listener: (context, locState) {
            if (locState is HelperLocationTracking) {
              final lat = locState.location.latitude;
              final lng = locState.location.longitude;
              _helperLat = lat;
              _helperLng = lng;
              unawaited(
                _updateHelperMarker(
                  lat,
                  lng,
                  heading: locState.location.heading,
                ),
              );
              final arrived = _distanceMeters(
                    lat,
                    lng,
                    booking.pickupLat,
                    booking.pickupLng,
                  ) <=
                  _pickupArrivalThresholdMeters;
              if (_hasArrivedAtPickup != arrived) {
                setState(() => _hasArrivedAtPickup = arrived);
              }
              if (_isFollowing) {
                if (navMode) {
                  _recenterNavigation(
                    lat,
                    lng,
                    heading: locState.location.heading,
                  );
                } else {
                  _recenter(lat, lng);
                }
              }
              // Re-draw route from helper's current position → destination.
              _onHelperLocationForRoute(lat, lng);
            }
          },
          child: const SizedBox.shrink(),
        ),

        // 2. Top Controls
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: AppTheme.spaceMD,
          child: ActiveBlurredCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.pop(),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: AppTheme.spaceMD,
          child: BlocBuilder<HelperLocationCubit, HelperLocationState>(
            builder: (context, locState) {
              return ActiveBlurredCircleButton(
                icon: Icons.my_location_rounded,
                onTap: () {
                  if (locState is HelperLocationTracking) {
                    setState(() => _isFollowing = true);
                    if (navMode) {
                      _recenterNavigation(
                        locState.location.latitude,
                        locState.location.longitude,
                        heading: locState.location.heading,
                      );
                    } else {
                      _recenter(
                        locState.location.latitude,
                        locState.location.longitude,
                      );
                    }
                  } else {
                    final lat = isStarted ? booking.destinationLat : booking.pickupLat;
                    final lng = isStarted ? booking.destinationLng : booking.pickupLng;
                    _recenter(lat, lng);
                  }
                },
              );
            },
          ),
        ),

        // Route info + trip stage pill
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 68,
          right: 68,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isStarted
                      ? BrandTokens.successGreen.withValues(alpha: 0.92)
                      : BrandTokens.warningAmber.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  isStarted ? 'Trip In Progress' : 'Heading To Pickup',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (_lastRoute != null) ...[
                const SizedBox(height: 8),
                ActiveRouteInfoChip(
                  distance: _lastRoute!.distanceLabel,
                  duration: _lastRoute!.durationLabel,
                ),
              ],
            ],
          ),
        ),

        // 3. Draggable Tracking Sheet
        BlocBuilder<HelperSosCubit, HelperSosState>(
          bloc: _sosCubit,
          builder: (context, sosState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.38,
              minChildSize: 0.22,
              maxChildSize: 0.75,
              builder: (context, scrollController) {
                return ActiveTrackingSheet(
                  scrollController: scrollController,
                  booking: booking,
                  isStarted: isStarted,
                  status: status,
                  hasArrivedAtPickup: _hasArrivedAtPickup,
                  distanceToPickupMeters: (_helperLat != null && _helperLng != null)
                      ? _distanceMeters(
                          _helperLat!,
                          _helperLng!,
                          booking.pickupLat,
                          booking.pickupLng,
                        )
                      : null,
                  sosState: sosState,
                  onEndTrip: () => _confirmEnd(context, booking),
                  onStartTrip: () => _tripActionCubit.startTrip(booking),
              onChat: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HelperChatPage(
                    bookingId: booking.id,
                    userName: booking.travelerName,
                    userAvatar: booking.travelerImage,
                  ),
                ),
              ),
                  onCancelSos: _sosCubit.deactivatePanic,
                );
              },
            );
          },
        ),

        // 4. SOS Button (Floating)
        Positioned(
          right: AppTheme.spaceMD,
          bottom: MediaQuery.of(context).size.height * 0.38 + 16,
          child: HelperSosFloatingButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SOS Button Pressed'), duration: Duration(seconds: 1)),
              );
              _openSosSheet(context);
            },
          ),
        ),

        // 5. SOS Active Banner (Top of everything)
        BlocBuilder<HelperSosCubit, HelperSosState>(
          bloc: _sosCubit,
          builder: (context, sosState) {
            if (sosState.status == SosStatus.active || sosState.status == SosStatus.activating) {
              return Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: AppTheme.spaceMD,
                right: AppTheme.spaceMD,
                child: HelperSosActiveBanner(
                  onCancel: _sosCubit.deactivatePanic,
                  isCancelling: sosState.status == SosStatus.deactivating || sosState.status == SosStatus.activating,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  void _openSosSheet(BuildContext context) {
    showHelperSosSheet(
      context,
      cubit: _sosCubit,
      onCancel: _sosCubit.deactivatePanic,
      onTrigger: (result) async {
        final locState = _locationCubit.state;
        double lat = 0, lng = 0;
        if (locState is HelperLocationTracking) {
          lat = locState.location.latitude;
          lng = locState.location.longitude;
        }
        
        try {
          await _sosCubit.activatePanic(
            bookingId: widget.bookingId,
            lat: lat,
            lng: lng,
            reason: result.reason.apiValue,
            note: result.note,
          );
          return null; // Success
        } catch (e) {
          return e.toString();
        }
      },
    );
  }

  void _completeTripAndExit() {
    _locationCubit.stopTripTracking();
    _activeCubit.clearCurrentId();
    _activeCubit.load(silent: true);
    if (mounted) context.pop();
  }

  void _confirmEnd(BuildContext context, HelperBooking booking) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BrandTokens.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('End Trip?', style: BrandTypography.headline(color: BrandTokens.textPrimary)),
        content: Text('Mark this trip as completed?', style: BrandTypography.body(color: BrandTokens.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: BrandTypography.body(color: BrandTokens.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _tripActionCubit.endTrip(booking);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandTokens.dangerRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('End Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTrip(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BrandTokens.successGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: BrandTokens.successGreen, size: 60),
          ),
          const SizedBox(height: 24),
          Text('No Active Trip', style: BrandTypography.headline()),
          const SizedBox(height: 8),
          Text("You don't have an active booking right now", style: BrandTypography.body(color: BrandTokens.textSecondary)),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandTokens.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Back to Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEarningsDialog(BuildContext context, double earnings, {VoidCallback? onDismiss}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: BrandTokens.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: BrandTokens.successGreen, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              Text('Trip Completed! 🎉', style: BrandTypography.headline()),
              const SizedBox(height: 6),
              Text('You earned', style: BrandTypography.body(color: BrandTokens.textSecondary)),
              const SizedBox(height: 4),
              Text('\$${earnings.toStringAsFixed(2)}',
                  style: BrandTypography.title(color: BrandTokens.successGreen).copyWith(fontSize: 42)),
              const SizedBox(height: 8),
              Text('How was your traveler?', style: BrandTypography.caption(color: BrandTokens.textSecondary)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.star_rounded, color: Colors.white),
                  label: const Text('Rate Traveler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () {
                    Navigator.pop(context);
                    onDismiss?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandTokens.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: Text('Skip', style: BrandTypography.body(color: BrandTokens.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? BrandTokens.dangerRed : BrandTokens.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}

