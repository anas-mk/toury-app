import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' hide Position, LocationSettings;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_button.dart';


class MapPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerPage({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  double _selectedLat = 30.0444;
  double _selectedLng = 31.2357;
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  PointAnnotation? _pin;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLat = widget.initialLat!;
      _selectedLng = widget.initialLng!;
    } else {
      _tryCenterOnCurrentLocation();
    }
  }

  Future<void> _tryCenterOnCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
      });
      _mapboxMap?.setCamera(CameraOptions(
        center: Point(coordinates: Position(position.longitude, position.latitude)),
        zoom: 15,
      ));
      _updatePin(position.latitude, position.longitude);
    } catch (_) {
      // Keep fallback center if current location is unavailable.
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _annotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    _updatePin(_selectedLat, _selectedLng);

    // Listen for map taps to update pin
    mapboxMap.setOnMapTapListener((context) {
      final lat = context.point.coordinates.lat.toDouble();
      final lng = context.point.coordinates.lng.toDouble();
      setState(() {
        _selectedLat = lat;
        _selectedLng = lng;
      });
      _updatePin(lat, lng);
    });
  }

  void _updatePin(double lat, double lng) async {
    if (_annotationManager == null) return;
    if (_pin != null) {
      await _annotationManager!.delete(_pin!);
    }
    _pin = await _annotationManager!.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(lng, lat)),
      iconImage: 'marker-15',
      iconSize: 2.5,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapPickerWidget"),
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(_selectedLng, _selectedLat)),
              zoom: 13.0,
            ),
            styleUri: MapboxStyles.LIGHT,
            onMapCreated: _onMapCreated,
          ),

          // ── Top Bar ─────────────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _GlassButton(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      border: Border.all(color: theme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tap to pin location',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColor.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedLat.toStringAsFixed(6)}, ${_selectedLng.toStringAsFixed(6)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Confirm Button ───────────────────────────────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 24,
            right: 24,
            child: CustomButton(
              onPressed: () => Navigator.pop(
                context,
                // Return as a simple map so callers don't need latlong2
                {'lat': _selectedLat, 'lng': _selectedLng},
              ),
              text: 'Confirm Location',
              icon: Icons.check_circle_rounded,
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _GlassButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
