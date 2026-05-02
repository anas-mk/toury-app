import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:toury/features/helper/features/helper_chat/presentation/pages/helper_chat_page.dart';
import 'package:toury/features/helper/features/helper_sos/presentation/pages/helper_sos_page.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/widgets/custom_button.dart';
import 'package:toury/features/helper/features/helper_bookings/presentation/cubit/trip_action_cubit.dart';
import 'package:toury/features/helper/features/helper_location/presentation/cubit/helper_location_cubit.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../helper_bookings/presentation/cubit/booking_actions_cubits.dart' show DeclineBookingCubit;
import '../../../helper_bookings/presentation/cubit/helper_bookings_cubits.dart';
import '../cubit/helper_tracking_cubit.dart';
import '../../../../../../core/services/maps/cached_tile_provider.dart';
import '../cubit/helper_tracking_state.dart';

const String _mapboxToken = 'pk.eyJ1IjoiYmVsYWxmYXd6eSIsImEiOiJjbW9ndWN1OHIwMDFnMnBzYm1wYTlrOGRoIn0.zhWYpDxePVXljYq4-2_OXg';

class HelperBookingTrackingPage extends StatefulWidget {
  final String bookingId;
  final double pickupLat;
  final double pickupLng;
  final double destLat;
  final double destLng;

  const HelperBookingTrackingPage({
    super.key,
    required this.bookingId,
    required this.pickupLat,
    required this.pickupLng,
    required this.destLat,
    required this.destLng,
  });

  @override
  State<HelperBookingTrackingPage> createState() => _HelperBookingTrackingPageState();
}

class _HelperBookingTrackingPageState extends State<HelperBookingTrackingPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  // Animation for marker movement
  LatLng? _oldLocation;
  AnimationController? _movementController;
  Animation<LatLng>? _movementAnimation;

  @override
  void initState() {
    super.initState();
    _movementController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
      setState(() {}); // Rebuild map to update marker position
    });

    // Start Real-time GPS Tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = sl<AuthService>().getToken();
      if (token != null) {
        sl<HelperLocationCubit>().startTripTracking(token, widget.bookingId);
      }
    });
  }

  @override
  void dispose() {
    _movementController?.dispose();
    _mapController.dispose();
    // Stop Trip Tracking when leaving the screen
    sl<HelperLocationCubit>().stopTripTracking();
    super.dispose();
  }

  void _animateMarker(LatLng newLocation) {
    if (_oldLocation == null) {
      _oldLocation = newLocation;
      return;
    }

    _movementAnimation = LatLngTween(
      begin: _oldLocation!,
      end: newLocation,
    ).animate(CurvedAnimation(
      parent: _movementController!,
      curve: Curves.easeInOut,
    ));

    _oldLocation = newLocation;
    _movementController!.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<TripActionCubit, TripActionState>(
            listener: (context, state) {
              if (state is TripActionSuccess) {
                final msg = state.message.toLowerCase();
                if (msg.contains('started')) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip Started!')));
                  context.read<HelperTrackingCubit>().startTracking(widget.bookingId);
                } else if (msg.contains('ended') || msg.contains('completed')) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip Ended Successfully!')));
                  Navigator.pop(context);
                }
              } else if (state is TripActionError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
          ),
          BlocListener<DeclineBookingCubit, DeclineBookingState>(
            listener: (context, state) {
              if (state is DeclineBookingSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip Cancelled')));
                Navigator.pop(context);
              } else if (state is DeclineBookingError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
          ),
        ],
        child: BlocConsumer<HelperTrackingCubit, HelperTrackingState>(
          listener: (context, state) {
          if (state is HelperTrackingLive && state.tracking.latestPoint != null) {
            final latest = state.tracking.latestPoint!;
            final newPos = LatLng(latest.latitude, latest.longitude);
            _animateMarker(newPos);

            if (state.isFollowing) {
              _mapController.move(newPos, _mapController.camera.zoom);
            }
          }
        },
        builder: (context, state) {
          if (state is HelperTrackingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HelperTrackingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Retry',
                    onPressed: () => context.read<HelperTrackingCubit>().startTracking(widget.bookingId),
                  ),
                ],
              ),
            );
          }

          if (state is HelperTrackingLive) {
            final tracking = state.tracking;
            final latest = tracking.latestPoint;
            final helperPos = latest != null ? LatLng(latest.latitude, latest.longitude) : null;
            final polylinePoints = tracking.history.map((e) => LatLng(e.latitude, e.longitude)).toList();

            return Stack(
              children: [
                // 1. MAP
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: helperPos ?? LatLng(widget.pickupLat, widget.pickupLng),
                    initialZoom: 15,
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture && state.isFollowing) {
                        context.read<HelperTrackingCubit>().toggleFollow(false);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: isDark
                          ? 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}@2x?access_token=$_mapboxToken'
                          : 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}@2x?access_token=$_mapboxToken',
                      additionalOptions: const {
                        'accessToken': _mapboxToken,
                      },
                      tileProvider: CachedTileProvider(),
                      userAgentPackageName: 'com.toury.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        if (polylinePoints.isNotEmpty)
                          Polyline(
                            points: polylinePoints,
                            color: BrandTokens.primaryBlue,
                            strokeWidth: 4,
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        // Pickup Marker
                        Marker(
                          point: LatLng(widget.pickupLat, widget.pickupLng),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                        ),
                        // Destination Marker
                        Marker(
                          point: LatLng(widget.destLat, widget.destLng),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.flag, color: Colors.red, size: 40),
                        ),
                        // Helper Marker (Animated)
                        if (helperPos != null)
                          Marker(
                            point: _movementAnimation?.value ?? helperPos,
                            width: 60,
                            height: 60,
                            child: Transform.rotate(
                              angle: (latest?.heading ?? 0) * (3.14159 / 180),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                                  border: Border.all(color: BrandTokens.primaryBlue, width: 3),
                                ),
                                child: const Icon(Icons.navigation, color: BrandTokens.primaryBlue, size: 30),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // 2. TOP BAR
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  right: 20,
                  child: _buildTopStatus(context, tracking.status),
                ),

                // 3. FLOATING BUTTONS
                Positioned(
                  bottom: 220,
                  right: 20,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'recenter',
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: () {
                          if (helperPos != null) {
                            _mapController.move(helperPos, 15);
                            context.read<HelperTrackingCubit>().toggleFollow(true);
                          }
                        },
                        child: const Icon(Icons.my_location, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: 'follow',
                        mini: true,
                        backgroundColor: state.isFollowing ? BrandTokens.primaryBlue : Colors.white,
                        onPressed: () => context.read<HelperTrackingCubit>().toggleFollow(!state.isFollowing),
                        child: Icon(
                          state.isFollowing ? Icons.lock : Icons.lock_open,
                          color: state.isFollowing ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. BOTTOM DASHBOARD
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildDashboard(context, tracking),
                ),

                // 5. BACK BUTTON
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
      ),
    );
  }

  Widget _buildTopStatus(BuildContext context, String status) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(status.toUpperCase(), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, dynamic tracking) {
    final theme = Theme.of(context);
    final s = tracking.status.toString().toLowerCase();
    
    final canChat = true; // Always allow chat
    final isStarted = ['inprogress', 'started'].contains(s);
    final canSos = isStarted;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat(context, 'ETA', '${tracking.etaMinutes ?? "--"} min', Icons.timer),
              _buildStat(context, 'Distance', '${((tracking.distanceToTarget ?? 0) / 1000).toStringAsFixed(1)} km', Icons.directions),
              _buildStat(context, 'Speed', '${(tracking.latestPoint?.speed ?? 0).toStringAsFixed(0)} km/h', Icons.speed),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(backgroundColor: BrandTokens.primaryBlue, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isStarted ? 'On Active Trip' : 'Waiting to Start', style: BrandTokens.body(fontWeight: FontWeight.bold)),
                    Text('Trip ID: #${widget.bookingId.substring(0, 8).toUpperCase()}', style: BrandTokens.body(fontSize: 12)),
                  ],
                ),
              ),
              if (canChat)
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: BrandTokens.primaryBlue),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => HelperChatPage(bookingId: widget.bookingId)));
                  },
                ),
              if (canSos)
                IconButton(
                  icon: const Icon(Icons.sos, color: BrandTokens.dangerRed),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => HelperSosPage(bookingId: widget.bookingId)));
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isStarted)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: BlocBuilder<TripActionCubit, TripActionState>(
                builder: (context, state) => ElevatedButton(
                  onPressed: state is TripActionInProgress ? null : () => context.read<TripActionCubit>().end(widget.bookingId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandTokens.dangerRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(state is TripActionInProgress ? 'Ending...' : 'End Trip', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<DeclineBookingCubit, DeclineBookingState>(
                    builder: (context, state) => OutlinedButton(
                      onPressed: state is DeclineBookingLoading ? null : () => context.read<DeclineBookingCubit>().decline(widget.bookingId, reason: 'Cancelled by helper'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: BrandTokens.dangerRed, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(state is DeclineBookingLoading ? '...' : 'Cancel', style: const TextStyle(color: BrandTokens.dangerRed, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BlocBuilder<TripActionCubit, TripActionState>(
                    builder: (context, state) => ElevatedButton(
                      onPressed: state is TripActionInProgress ? null : () => context.read<TripActionCubit>().start(widget.bookingId),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: BrandTokens.successGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(state is TripActionInProgress ? 'Starting...' : 'Start Trip', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: BrandTokens.primaryBlue, size: 24),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end}) : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}
