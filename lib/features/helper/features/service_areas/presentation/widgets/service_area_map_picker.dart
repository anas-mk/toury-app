import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';

class ServiceAreaMapPicker extends StatefulWidget {
  final LatLng initialLocation;
  final ValueChanged<LatLng> onLocationChanged;
  final double radiusKm;

  const ServiceAreaMapPicker({
    super.key,
    required this.initialLocation,
    required this.onLocationChanged,
    required this.radiusKm,
  });

  @override
  State<ServiceAreaMapPicker> createState() => _ServiceAreaMapPickerState();
}

class _ServiceAreaMapPickerState extends State<ServiceAreaMapPicker> {
  late LatLng _currentLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppColor.lightBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 12.0,
              onTap: (_, latLng) {
                setState(() {
                  _currentLocation = latLng;
                });
                widget.onLocationChanged(latLng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.toury.app',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _currentLocation,
                    radius: widget.radiusKm * 1000, // radius is in meters
                    useRadiusInMeter: true,
                    color: AppColor.primaryColor.withOpacity(0.2),
                    borderColor: AppColor.primaryColor,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColor.destinationColor,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: AppTheme.spaceSM,
            right: AppTheme.spaceSM,
            child: FloatingActionButton.small(
              heroTag: 'map_center',
              onPressed: () {
                _mapController.move(_currentLocation, 12.0);
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: AppColor.primaryColor),
            ),
          ),
          Positioned(
            bottom: AppTheme.spaceSM,
            left: AppTheme.spaceSM,
            right: AppTheme.spaceSM,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: AppTheme.spaceXS,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Text(
                'Lat: ${_currentLocation.latitude.toStringAsFixed(4)}, Lng: ${_currentLocation.longitude.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
