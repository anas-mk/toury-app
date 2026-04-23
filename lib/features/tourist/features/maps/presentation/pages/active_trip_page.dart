import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../core/entities/location_entity.dart';

class ActiveTripPage extends StatelessWidget {
  final LocationEntity userLocation;
  final LocationEntity helperLocation;
  final String status;

  const ActiveTripPage({
    super.key,
    required this.userLocation,
    required this.helperLocation,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final userLatLng = LatLng(userLocation.lat, userLocation.lng);
    final helperLatLng = LatLng(helperLocation.lat, helperLocation.lng);

    return Scaffold(
      appBar: AppBar(title: const Text('Active Trip')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: userLatLng,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.toury',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [userLatLng, helperLatLng],
                    color: Colors.blue,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: userLatLng,
                    child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                  ),
                  Marker(
                    point: helperLatLng,
                    child: const Icon(Icons.directions_car, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: Text('Status: ${status.toUpperCase()}'),
                subtitle: const Text('Helper is on the way'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}