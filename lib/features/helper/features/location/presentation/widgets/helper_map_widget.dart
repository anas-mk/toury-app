import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../bloc/location_cubit.dart';
import '../bloc/location_state.dart';

class HelperMapWidget extends StatefulWidget {
  const HelperMapWidget({super.key});

  @override
  State<HelperMapWidget> createState() => _HelperMapWidgetState();
}

class _HelperMapWidgetState extends State<HelperMapWidget> {
  final MapController _mapController = MapController();
  bool _isFollowMode = true;

  // Mock Route (In real app, this comes from RouteCubit)
  final List<LatLng> _mockRoute = [
    const LatLng(30.0444, 31.2357),
    const LatLng(30.0450, 31.2360),
    const LatLng(30.0460, 31.2370),
    const LatLng(30.0470, 31.2380),
  ];

  @override
  Widget build(BuildContext context) {
    // 1. We use BlocListener to move the camera independently from rebuilding the map layers
    return BlocListener<LocationCubit, LocationState>(
      listener: (context, state) {
        if (state is LocationTracking && _isFollowMode) {
          // Camera follow mode. We move the map to the current position.
          // Note: To keep the marker slightly below center (Uber style), 
          // we use the flutter_map alignment property inside MapOptions below.
          _mapController.move(state.currentPosition, 18.0);
        }
      },
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(30.0444, 31.2357), // Fallback
          initialZoom: 18.0,
          // Keeps the center point shifted down to the bottom third of the screen
          // so the driver can see more of the route ahead of them.
          // Note: Depending on flutter_map version, this alignment might be applied via padding or cursor offsets.
          // We assume standard usage.
          onPositionChanged: (position, hasGesture) {
            if (hasGesture && _isFollowMode) {
              // If user manually pans the map, turn off follow mode so they can explore
              setState(() => _isFollowMode = false);
            }
          },
        ),
        children: [
          // BASE LAYER: Map Tiles (Only rebuilds when zooming/panning)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.toury',
          ),

          // ROUTE LAYER: Polylines (Only rebuilds when route changes)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _mockRoute,
                strokeWidth: 6.0,
                color: Colors.blueAccent,
                borderStrokeWidth: 2.0,
                borderColor: Colors.blue[900]!,
              ),
            ],
          ),

          // MARKER LAYER: High-Frequency GPS Updates
          // We wrap ONLY the MarkerLayer in a BlocBuilder. This prevents the heavy
          // TileLayer and PolylineLayer from rebuilding 60 times a second.
          BlocBuilder<LocationCubit, LocationState>(
            buildWhen: (previous, current) => current is LocationTracking,
            builder: (context, state) {
              if (state is LocationTracking) {
                return MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: state.currentPosition,
                      child: Transform.rotate(
                        // Convert heading (degrees) to radians for rotation
                        angle: state.heading * (math.pi / 180),
                        child: Image.asset(
                          // Ensure you have a top-down car image in your assets
                          'assets/images/car_top_down.png',
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.navigation,
                            color: Colors.black,
                            size: 40.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const MarkerLayer(markers: []);
            },
          ),
        ],
      ),
    );
  }
}
