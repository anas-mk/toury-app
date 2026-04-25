import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../cubit/tracking_cubit.dart';
import '../cubit/tracking_state.dart';

class UserBookingTrackingPage extends StatefulWidget {
  final String bookingId;
  final LatLng pickupLocation;
  final LatLng destinationLocation;

  const UserBookingTrackingPage({
    super.key,
    required this.bookingId,
    required this.pickupLocation,
    required this.destinationLocation,
  });

  @override
  State<UserBookingTrackingPage> createState() => _UserBookingTrackingPageState();
}

class _UserBookingTrackingPageState extends State<UserBookingTrackingPage> {
  final MapController _mapController = MapController();
  bool _followHelper = true;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TrackingCubit>()..startTracking(widget.bookingId),
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Map Layer
            BlocConsumer<TrackingCubit, TrackingState>(
              listener: (context, state) {
                if (state is TrackingLive && _followHelper && state.tracking.latestPoint != null) {
                  _mapController.move(
                    LatLng(state.tracking.latestPoint!.latitude, state.tracking.latestPoint!.longitude),
                    _mapController.camera.zoom,
                  );
                }
              },
              builder: (context, state) {
                LatLng? helperPos;
                List<LatLng> polylinePoints = [];

                if (state is TrackingLive) {
                  if (state.tracking.latestPoint != null) {
                    helperPos = LatLng(state.tracking.latestPoint!.latitude, state.tracking.latestPoint!.longitude);
                  }
                  polylinePoints = state.tracking.history
                      .map((p) => LatLng(p.latitude, p.longitude))
                      .toList();
                  if (helperPos != null) polylinePoints.add(helperPos);
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.pickupLocation,
                    initialZoom: 15,
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture && _followHelper) {
                        setState(() => _followHelper = false);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.toury.app',
                    ),
                    if (polylinePoints.isNotEmpty)
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
                          point: widget.pickupLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                        ),
                        // Destination Marker
                        Marker(
                          point: widget.destinationLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.flag, color: Colors.red, size: 40),
                        ),
                        // Helper Marker
                        if (helperPos != null)
                          Marker(
                            point: helperPos,
                            width: 60,
                            height: 60,
                            child: _buildHelperMarker(state is TrackingLive ? state.tracking.latestPoint?.heading : 0),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),

            // 2. Top Status Bar
            _buildTopStatus(),

            // 3. Floating Actions
            _buildFloatingActions(),

            // 4. Bottom Info Sheet
            _buildBottomInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHelperMarker(double? heading) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: (heading ?? 0) * (3.14159 / 180)),
      duration: const Duration(milliseconds: 500),
      builder: (context, rotation, child) {
        return Transform.rotate(
          angle: rotation,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColor.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.navigation, color: Colors.white, size: 24),
          ),
        );
      },
    );
  }

  Widget _buildTopStatus() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: BlocBuilder<TrackingCubit, TrackingState>(
        builder: (context, state) {
          bool isLive = state is TrackingLive && !state.isReconnecting;
          return CustomCard(
            variant: CardVariant.glass,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isLive ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isLive ? 'LIVE TRACKING' : 'CONNECTING...',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Positioned(
      bottom: 240,
      right: 20,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: 'recenter',
            backgroundColor: Colors.white,
            onPressed: () {
              final state = context.read<TrackingCubit>().state;
              if (state is TrackingLive && state.tracking.latestPoint != null) {
                _mapController.move(
                  LatLng(state.tracking.latestPoint!.latitude, state.tracking.latestPoint!.longitude),
                  15,
                );
                setState(() => _followHelper = true);
              }
            },
            child: Icon(Icons.my_location, color: _followHelper ? AppColor.primaryColor : Colors.grey),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            backgroundColor: Colors.white,
            onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
            child: const Icon(Icons.add, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 220,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
        ),
        child: BlocBuilder<TrackingCubit, TrackingState>(
          builder: (context, state) {
            if (state is TrackingLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TrackingError) {
              return Center(child: Text(state.message));
            }

            if (state is TrackingLive) {
              final t = state.tracking;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColor.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t.status.toUpperCase(),
                          style: const TextStyle(color: AppColor.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${t.etaMinutes ?? "--"} mins',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Distance', '${t.distanceToTarget?.toStringAsFixed(1) ?? "--"} km', Icons.straighten),
                      _buildStatItem('Speed', '${t.latestPoint?.speed?.toStringAsFixed(0) ?? "0"} km/h', Icons.speed),
                      _buildStatItem('Phase', t.status, Icons.info_outline),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {}, // Chat or Call shortcut
                      child: const Text('Contact Helper', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
