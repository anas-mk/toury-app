import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' hide Position, LocationSettings;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/theme/app_color.dart';

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
      _mapboxMap?.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 15,
        ),
      );
      _updatePin(position.latitude, position.longitude);
    } catch (_) {
      // Keep fallback center if current location is unavailable.
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _annotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();
    _updatePin(_selectedLat, _selectedLng);

    mapboxMap.setOnMapTapListener((context) {
      HapticService.light();
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
    _pin = await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        iconImage: 'marker-15',
        iconSize: 2.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mapPickerWidget'),
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(_selectedLng, _selectedLat),
              ),
              zoom: 13.0,
            ),
            styleUri: palette.isDark ? MapboxStyles.DARK : MapboxStyles.LIGHT,
            onMapCreated: _onMapCreated,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _GlassIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () {
                    HapticService.light();
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 12),
                Expanded(child: _CoordinateBanner(lat: _selectedLat, lng: _selectedLng)),
              ],
            ),
          ),
          Center(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: palette.primary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: palette.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: palette.primary.withValues(alpha: 0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.place_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 24,
            right: 24,
            child: _ConfirmButton(
              onPressed: () {
                HapticService.medium();
                Navigator.pop(
                  context,
                  {'lat': _selectedLat, 'lng': _selectedLng},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  CHROME WIDGETS
// ──────────────────────────────────────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border, width: 0.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: palette.textPrimary),
        ),
      ),
    );
  }
}

class _CoordinateBanner extends StatelessWidget {
  final double lat;
  final double lng;

  const _CoordinateBanner({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_rounded, color: palette.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tap anywhere to pin',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ConfirmButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary,
            const Color(0xFF7B61FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Confirm Location',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
