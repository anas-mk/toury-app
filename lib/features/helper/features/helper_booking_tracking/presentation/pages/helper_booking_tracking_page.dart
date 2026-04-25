import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../cubit/helper_tracking_cubit.dart';
import '../cubit/helper_tracking_state.dart';

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
  }

  @override
  void dispose() {
    _movementController?.dispose();
    _mapController.dispose();
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
    return Scaffold(
      body: BlocConsumer<HelperTrackingCubit, HelperTrackingState>(
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
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.toury.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: polylinePoints,
                          color: AppColor.primaryColor,
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
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                                  border: Border.all(color: AppColor.primaryColor, width: 3),
                                ),
                                child: const Icon(Icons.navigation, color: AppColor.primaryColor, size: 30),
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
                  child: _buildTopStatus(tracking.status),
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
                        backgroundColor: state.isFollowing ? AppColor.primaryColor : Colors.white,
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
                  child: _buildDashboard(tracking),
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
    );
  }

  Widget _buildTopStatus(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
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
          Text(status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDashboard(dynamic tracking) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('ETA', '${tracking.etaMinutes ?? "--"} min', Icons.timer),
              _buildStat('Distance', '${((tracking.distanceToTarget ?? 0) / 1000).toStringAsFixed(1)} km', Icons.directions),
              _buildStat('Speed', '${(tracking.latestPoint?.speed ?? 0).toStringAsFixed(0)} km/h', Icons.speed),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(backgroundColor: AppColor.primaryColor, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('On Active Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Trip ID: #TOUR-8293', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              CustomButton(
                text: 'Contact Support',
                variant: ButtonVariant.outlined,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColor.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
