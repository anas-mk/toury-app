import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/helper/features/helper_bookings/presentation/cubit/trip_action_cubit.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/config/api_config.dart';
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
import '../../../helper_sos/presentation/widgets/helper_sos_floating_button.dart';
import '../../../helper_sos/presentation/widgets/helper_sos_sheet.dart';
import '../../../helper_sos/presentation/cubit/helper_sos_cubit.dart';
import '../../../helper_sos/presentation/widgets/helper_sos_active_banner.dart';

class ActiveBookingPage extends StatefulWidget {
  final String bookingId;
  const ActiveBookingPage({super.key, required this.bookingId});

  @override
  State<ActiveBookingPage> createState() => _ActiveBookingPageState();
}

class _ActiveBookingPageState extends State<ActiveBookingPage> {
  late final ActiveBookingCubit _activeCubit;
  late final TripActionCubit _tripActionCubit;
  final _directions = MapboxDirectionsService();
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  HelperBooking? _currentBooking;
  RouteResult? _lastRoute; // cached for the info chip
  bool _isFollowing = true;
  Timer? _routeDebounce;   // throttle real-time updates to 1 call / 10 s

  @override
  void initState() {
    super.initState();
    _activeCubit = sl<ActiveBookingCubit>();
    _tripActionCubit = sl<TripActionCubit>();
    
    // Start trip tracking if we have an ID
    if (widget.bookingId.isNotEmpty) {
      final token = sl<AuthService>().getToken();
      if (token != null) {
        sl<HelperLocationCubit>().startTripTracking(token, widget.bookingId);
      }
      _activeCubit.loadById(widget.bookingId);
    } else {
      _activeCubit.load();
    }
  }

  @override
  void dispose() {
    _routeDebounce?.cancel();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    _polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();
    
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

  // ── Route drawing ───────────────────────────────────────────────────────

  /// Initial draw: route from pickup → destination using Directions API.
  void _drawRoute(HelperBooking booking) async {
    await _fetchAndDrawRoute(
      fromLat: booking.pickupLat,
      fromLng: booking.pickupLng,
      toLat: booking.destinationLat,
      toLng: booking.destinationLng,
      booking: booking,
    );
  }

  /// Called when the helper's GPS updates — re-routes from helper → destination.
  void _onHelperLocationForRoute(double helperLat, double helperLng) {
    final booking = _currentBooking;
    if (booking == null) return;
    // Debounce: only re-fetch every 10 seconds to respect API limits.
    if (_routeDebounce?.isActive == true) return;
    _routeDebounce = Timer(const Duration(seconds: 10), () {});
    _fetchAndDrawRoute(
      fromLat: helperLat,
      fromLng: helperLng,
      toLat: booking.destinationLat,
      toLng: booking.destinationLng,
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
      geometry: Point(coordinates: Position(booking.destinationLng, booking.destinationLat)),
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
        lineColor: BrandTokens.primaryBlue.value,
        lineWidth: 3.5,
        lineOpacity: 0.6,
      ));
      return;
    }

    // Cache for the distance/duration chip.
    if (mounted) setState(() => _lastRoute = route);

    // Convert [[lng, lat], ...] → Mapbox Position list.
    final positions = route.coordinates
        .map((c) => Position(c[0], c[1]))
        .toList();

    await _polylineAnnotationManager!.create(PolylineAnnotationOptions(
      geometry: LineString(coordinates: positions),
      lineColor: BrandTokens.primaryBlue.value,
      lineWidth: 5.0,
      lineOpacity: 0.85,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _activeCubit),
        BlocProvider.value(value: _tripActionCubit),
        BlocProvider.value(value: sl<HelperLocationCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<TripActionCubit, TripActionState>(
            listener: (context, state) {
              if (state is TripActionSuccess) {
                if (state.actionType == 'start') {
                  _showSnack(context, '🚀 Trip started!');
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
                        sl<HelperLocationCubit>().stopTripTracking();
                        _activeCubit.clearCurrentId();
                        _activeCubit.load(silent: true);
                        context.pop();
                      });
                    } else {
                      sl<HelperLocationCubit>().stopTripTracking();
                      _activeCubit.clearCurrentId();
                      _activeCubit.load(silent: true);
                      context.pop();
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
    final theme = Theme.of(context);
    final status = booking.status.toLowerCase();
    final isStarted = status == 'inprogress' || status == 'started';
    
    final initialCenter = isStarted ? Position(booking.destinationLng, booking.destinationLat) : Position(booking.pickupLng, booking.pickupLat);

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
              if (_isFollowing) _recenter(lat, lng);
              // Re-draw route from helper's current position → destination.
              _onHelperLocationForRoute(lat, lng);
            }
          },
          child: const SizedBox.shrink(),
        ),

        // 2. Blurred Top Buttons
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: AppTheme.spaceMD,
          child: _BlurredCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.pop(),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: AppTheme.spaceMD,
          child: BlocBuilder<HelperLocationCubit, HelperLocationState>(
            builder: (context, locState) {
              return _BlurredCircleButton(
                icon: Icons.my_location_rounded,
                onTap: () {
                  if (locState is HelperLocationTracking) {
                    setState(() => _isFollowing = true);
                    _recenter(locState.location.latitude, locState.location.longitude);
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

        // Route info chip — top-center, shows km + ETA once route is loaded.
        if (_lastRoute != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 64,
            right: 64,
            child: Center(
              child: _RouteInfoChip(
                distance: _lastRoute!.distanceLabel,
                duration: _lastRoute!.durationLabel,
              ),
            ),
          ),

        // 3. Draggable Tracking Sheet
        BlocBuilder<HelperSosCubit, HelperSosState>(
          bloc: sl<HelperSosCubit>(),
          builder: (context, sosState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.38,
              minChildSize: 0.22,
              maxChildSize: 0.75,
              builder: (context, scrollController) {
                return _TrackingSheet(
                  scrollController: scrollController,
                  booking: booking,
                  isStarted: isStarted,
                  status: status,
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
                  onCancelSos: () => sl<HelperSosCubit>().deactivatePanic(),
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
          bloc: sl<HelperSosCubit>(),
          builder: (context, sosState) {
            if (sosState.status == SosStatus.active || sosState.status == SosStatus.activating) {
              return Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: AppTheme.spaceMD,
                right: AppTheme.spaceMD,
                child: HelperSosActiveBanner(
                  onCancel: () => sl<HelperSosCubit>().deactivatePanic(),
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
    debugPrint('ActiveBookingPage: Opening SOS Sheet');
    showHelperSosSheet(
      context,
      cubit: sl<HelperSosCubit>(),
      onCancel: () => sl<HelperSosCubit>().deactivatePanic(),
      onTrigger: (result) async {
        debugPrint('ActiveBookingPage: SOS Triggered with reason: ${result.reason.apiValue}');
        final locState = sl<HelperLocationCubit>().state;
        double lat = 0, lng = 0;
        if (locState is HelperLocationTracking) {
          lat = locState.location.latitude;
          lng = locState.location.longitude;
        }
        
        try {
          await sl<HelperSosCubit>().activatePanic(
            bookingId: widget.bookingId,
            lat: lat,
            lng: lng,
            reason: result.reason.apiValue,
            note: result.note,
          );
          debugPrint('ActiveBookingPage: SOS Activated successfully');
          return null; // Success
        } catch (e) {
          debugPrint('ActiveBookingPage: SOS Activation failed: $e');
          return e.toString();
        }
      },
    );
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

class _TrackingSheet extends StatelessWidget {
  final ScrollController scrollController;
  final HelperBooking booking;
  final bool isStarted;
  final String status;
  final VoidCallback onEndTrip;
  final VoidCallback onStartTrip;
  final VoidCallback onChat;
  final HelperSosState sosState;
  final VoidCallback onCancelSos;


  const _TrackingSheet({
    required this.scrollController,
    required this.booking,
    required this.isStarted,
    required this.status,
    required this.onEndTrip,
    required this.onStartTrip,
    required this.onChat,
    required this.sosState,
    required this.onCancelSos,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0E1A) : BrandTokens.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: BrandTokens.borderSoft,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(AppTheme.spaceLG, AppTheme.spaceLG, AppTheme.spaceLG, 0),
              children: [
                // Traveler Info Row
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: BrandTokens.primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          booking.travelerName.isNotEmpty ? booking.travelerName[0].toUpperCase() : '?',
                          style: BrandTypography.title(color: BrandTokens.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.travelerName, style: BrandTypography.title()),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isStarted ? BrandTokens.successGreen : BrandTokens.warningAmber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isStarted ? 'Trip in progress' : 'Ready to start',
                                style: BrandTypography.caption(color: BrandTokens.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _SheetIconButton(icon: Icons.chat_bubble_rounded, color: BrandTokens.primaryBlue, onTap: onChat),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spaceXL),
                
                // Stats Row
                Row(
                  children: [
                    _StatItem(label: 'Payout', value: '\$${booking.payout.toStringAsFixed(0)}', icon: Icons.attach_money_rounded),
                    _StatItem(label: 'Language', value: booking.language ?? 'Any', icon: Icons.translate_rounded),
                    _StatItem(label: 'Type', value: booking.isInstant ? 'Instant' : 'Scheduled', icon: Icons.bolt_rounded),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spaceXL),
                
                // Route
                _RouteInfo(pickup: booking.pickupLocation, destination: booking.destinationLocation),
                const SizedBox(height: 120), // Padding for fixed buttons
              ],
            ),
          ),
          
          // Fixed Actions at Bottom
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A0E1A) : BrandTokens.surfaceWhite,
              border: Border(top: BorderSide(color: BrandTokens.borderSoft.withValues(alpha: 0.2))),
            ),
            child: SafeArea(
              top: false,
              child: _buildActions(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final s = status.toLowerCase();
    final tripActive = isStarted || s.contains('progress') || s.contains('started');

    // Case 1: Trip can be started (Accepted/Confirmed but not in progress)
    if (booking.canStartTrip || (s.contains('accept') && !tripActive)) {
      return _TripBtn(
        label: 'Start Trip',
        color: BrandTokens.successGreen,
        icon: Icons.play_arrow_rounded,
        onTap: onStartTrip,
        actionType: 'start',
      );
    } 
    
    // Case 2: Trip is active (In Progress)
    if (booking.canEndTrip || tripActive) {
      final isSosActive = sosState.status == SosStatus.active;
      final isSosPending = sosState.status == SosStatus.deactivating || sosState.status == SosStatus.activating;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSosActive || isSosPending) ...[
            _TripBtn(
              label: isSosPending ? 'Cancelling SOS...' : 'Cancel SOS Alert',
              color: BrandTokens.dangerRed,
              icon: Icons.cancel_outlined,
              onTap: isSosPending ? null : onCancelSos,
              actionType: 'cancel_sos',
            ),
            const SizedBox(height: AppTheme.spaceMD),
          ],
          _TripBtn(
            label: 'End Trip',
            color: BrandTokens.dangerRed,
            icon: Icons.stop_circle_rounded,
            onTap: onEndTrip,
            actionType: 'end',
          ),
        ],
      );
    }

    // Fallback: Just show End Trip if nothing else matches but it's not completed
    if (s != 'completed' && s != 'cancelled') {
       return _TripBtn(
          label: 'End Trip',
          color: BrandTokens.dangerRed,
          icon: Icons.stop_circle_rounded,
          onTap: onEndTrip,
          actionType: 'end',
        );
    }

    return const SizedBox.shrink();
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: BrandTokens.textSecondary, size: 20),
          const SizedBox(height: 4),
          Text(value, style: BrandTypography.body(weight: FontWeight.bold)),
          Text(label, style: BrandTypography.caption(color: BrandTokens.textSecondary)),
        ],
      ),
    );
  }
}

class _RouteInfo extends StatelessWidget {
  final String pickup, destination;
  const _RouteInfo({required this.pickup, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BrandTokens.borderSoft.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _RouteRow(icon: Icons.trip_origin_rounded, color: BrandTokens.successGreen, label: 'Pickup', value: pickup),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 2, height: 20, color: BrandTokens.borderSoft),
            ),
          ),
          _RouteRow(icon: Icons.location_on_rounded, color: BrandTokens.dangerRed, label: 'Drop-off', value: destination),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _RouteRow({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: BrandTypography.caption(color: BrandTokens.textSecondary)),
              Text(value, style: BrandTypography.body(weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
   final VoidCallback? onTap;
  final bool outline;

  final String? actionType;

  const _TripBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    this.outline = false,
    this.actionType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripActionCubit, TripActionState>(
      builder: (context, state) {
        final loading = state is TripActionLoading && state.actionType == actionType;
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onTap,
            icon: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon, color: outline ? color : Colors.white),
            label: Text(label, style: TextStyle(color: outline ? color : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: outline ? Colors.transparent : color,
              elevation: 0,
              side: outline ? BorderSide(color: color, width: 2) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        );
      },
    );
  }
}

class _SheetIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SheetIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
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
          color: Colors.white.withValues(alpha: 0.8),
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

class _PinDot extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _PinDot({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
        ],
        border: Border.all(color: color, width: 2.5),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _HelperMarker extends StatelessWidget {
  final double rotation;
  const _HelperMarker({required this.rotation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BrandTokens.primaryBlue.withValues(alpha: 0.2),
          ),
        ),
        // Helper Dot
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BrandTokens.primaryBlue,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        // Directional Arrow
        Transform.rotate(
          angle: rotation * (math.pi / 180),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.navigation_rounded,
                size: 20,
                color: BrandTokens.primaryBlue,
              ),
              const SizedBox(height: 28), 
            ],
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
              const Icon(Icons.straighten_rounded, size: 16,
                  color: BrandTokens.primaryBlue),
              const SizedBox(width: 6),
              Text(distance,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BrandTokens.textPrimary)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 1,
                height: 16,
                color: BrandTokens.borderSoft,
              ),
              const Icon(Icons.schedule_rounded, size: 16,
                  color: BrandTokens.primaryBlue),
              const SizedBox(width: 6),
              Text(duration,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BrandTokens.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
