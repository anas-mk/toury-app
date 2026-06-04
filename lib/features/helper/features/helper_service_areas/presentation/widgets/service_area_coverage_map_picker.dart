import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
    hide LocationSettings, Size;

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/services/location_cubit_impl.dart';
import '../../../../../../core/theme/app_color.dart';

/// Result from the full-screen coverage map picker.
class ServiceAreaMapPickResult {
  final double lat;
  final double lng;
  final double radiusKm;

  const ServiceAreaMapPickResult({
    required this.lat,
    required this.lng,
    required this.radiusKm,
  });
}

/// Full-screen map: tap center + adjust coverage radius (circle on map).
class ServiceAreaCoverageMapPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final double initialRadiusKm;

  const ServiceAreaCoverageMapPicker({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialRadiusKm = 10,
  });

  static Future<ServiceAreaMapPickResult?> show(
    BuildContext context, {
    double? initialLat,
    double? initialLng,
    double initialRadiusKm = 10,
  }) {
    return Navigator.of(context).push<ServiceAreaMapPickResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ServiceAreaCoverageMapPicker(
          initialLat: initialLat,
          initialLng: initialLng,
          initialRadiusKm: initialRadiusKm,
        ),
      ),
    );
  }

  @override
  State<ServiceAreaCoverageMapPicker> createState() =>
      _ServiceAreaCoverageMapPickerState();
}

class _ServiceAreaCoverageMapPickerState
    extends State<ServiceAreaCoverageMapPicker> {
  static const _radiusPresets = [5, 10, 15, 20];
  static const _minRadiusKm = 3.0;
  static const _maxRadiusKm = 25.0;

  late double _centerLat;
  late double _centerLng;
  late double _radiusKm;

  MapboxMap? _mapboxMap;
  bool _mapReady = false;
  bool _isLocating = false;
  PolygonAnnotationManager? _polygonManager;
  PolygonAnnotation? _coveragePolygon;
  CircleAnnotationManager? _centerDotManager;

  /// Serializes map annotation updates so rapid radius changes don't stack circles.
  Future<void>? _mapVisualSyncChain;
  int _mapVisualGeneration = 0;

  bool get _useSavedCenter =>
      widget.initialLat != null && widget.initialLng != null;

  @override
  void initState() {
    super.initState();
    _radiusKm = widget.initialRadiusKm.clamp(_minRadiusKm, _maxRadiusKm);
    if (_useSavedCenter) {
      _centerLat = widget.initialLat!;
      _centerLng = widget.initialLng!;
    } else {
      _centerLat = 30.0444;
      _centerLng = 31.2357;
      unawaited(_centerOnUserLocation());
    }
  }

  /// Used on first open — may use cached GPS for a faster start.
  Future<void> _centerOnUserLocation() async {
    if (!mounted) return;
    setState(() => _isLocating = true);
    try {
      final coords = await _fetchCurrentCoordinates(preferCache: true);
      if (coords != null && mounted) {
        _setCoverageCenter(coords.lat, coords.lng, animateCamera: _mapReady);
      }
    } catch (_) {
      if (mounted) {
        _showLocationMessage('Could not get your location. Tap the target button to retry.');
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// My-location button — fresh GPS + move coverage circle + fly camera to you.
  Future<void> _goToMyLocation() async {
    if (!mounted) return;
    HapticService.medium();
    setState(() => _isLocating = true);
    // Cancel any in-flight map draw so the circle always ends on you.
    _mapVisualGeneration++;

    try {
      final coords = await _fetchCurrentCoordinates(preferCache: false);
      if (coords == null || !mounted) return;

      _setCoverageCenter(coords.lat, coords.lng, animateCamera: true);
      HapticService.light();
    } catch (_) {
      if (mounted) {
        _showLocationMessage('Could not get your location. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<({double lat, double lng})?> _fetchCurrentCoordinates({
    required bool preferCache,
  }) async {
    if (preferCache) {
      final cached = await sl<LocationCubit>().requireLocation();
      if (cached != null) return cached;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      _showLocationMessage('Turn on location services to use your position.');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      _showLocationMessage('Location permission is required to show your position.');
      return null;
    }
    if (permission == LocationPermission.deniedForever) {
      _showLocationMessage('Enable location permission in system settings.');
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return (lat: position.latitude, lng: position.longitude);
  }

  void _showLocationMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setCoverageCenter(
    double lat,
    double lng, {
    bool animateCamera = false,
  }) {
    if (!mounted) return;
    setState(() {
      _centerLat = lat;
      _centerLng = lng;
      _isLocating = false;
    });
    if (_mapReady) _syncMapVisuals(animateCamera: animateCamera);
  }

  Future<void> _enableUserLocationPuck(MapboxMap mapboxMap) async {
    final palette = AppColors.of(context);
    try {
      await mapboxMap.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          showAccuracyRing: true,
          puckBearingEnabled: true,
          pulsingColor: palette.primary.toARGB32(),
        ),
      );
    } catch (_) {}
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    mapboxMap.logo.updateSettings(LogoSettings(enabled: false));
    mapboxMap.attribution.updateSettings(AttributionSettings(enabled: false));
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

    await _enableUserLocationPuck(mapboxMap);

    _polygonManager =
        await mapboxMap.annotations.createPolygonAnnotationManager();
    // Created after polygon so the center dot renders above the fill.
    _centerDotManager =
        await mapboxMap.annotations.createCircleAnnotationManager();

    mapboxMap.setOnMapTapListener((context) {
      HapticService.light();
      setState(() {
        _centerLat = context.point.coordinates.lat.toDouble();
        _centerLng = context.point.coordinates.lng.toDouble();
      });
      _syncMapVisuals();
    });

    _mapReady = true;
    if (!_isLocating) _syncMapVisuals();
  }

  void _syncMapVisuals({bool animateCamera = false}) {
    if (!_mapReady) return;
    final generation = ++_mapVisualGeneration;
    _mapVisualSyncChain = (_mapVisualSyncChain ?? Future<void>.value())
        .then(
          (_) => _applyMapVisuals(
            generation,
            animateCamera: animateCamera,
          ),
        )
        .catchError((_) {});
  }

  Future<void> _applyMapVisuals(
    int generation, {
    bool animateCamera = false,
  }) async {
    if (!_mapReady || !mounted || generation != _mapVisualGeneration) return;

    final lat = _centerLat;
    final lng = _centerLng;
    final radiusKm = _radiusKm;

    await _updateCoveragePolygon(lat, lng, radiusKm, generation);
    if (!mounted || generation != _mapVisualGeneration) return;

    await _updateCenterMarker(lat, lng, generation);
    if (!mounted || generation != _mapVisualGeneration) return;

    _fitCameraToCoverage(animate: animateCamera);
  }

  Future<void> _updateCoveragePolygon(
    double lat,
    double lng,
    double radiusKm,
    int generation,
  ) async {
    final manager = _polygonManager;
    if (manager == null || !mounted) return;

    final fillColor =
        AppColors.of(context).primary.withValues(alpha: 0.22).toARGB32();
    final outlineColor =
        AppColors.of(context).primary.withValues(alpha: 0.85).toARGB32();

    await manager.deleteAll();
    _coveragePolygon = null;

    if (!mounted || generation != _mapVisualGeneration) return;

    final ring = _circleRing(lat, lng, radiusKm);
    _coveragePolygon = await manager.create(
      PolygonAnnotationOptions(
        geometry: Polygon(coordinates: [ring]),
        fillColor: fillColor,
        fillOutlineColor: outlineColor,
      ),
    );
  }

  Future<void> _updateCenterMarker(
    double lat,
    double lng,
    int generation,
  ) async {
    final manager = _centerDotManager;
    if (manager == null || !mounted) return;

    final palette = AppColors.of(context);

    await manager.deleteAll();

    if (!mounted || generation != _mapVisualGeneration) return;

    await manager.create(
      CircleAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        circleRadius: 11,
        circleColor: palette.primary.toARGB32(),
        circleStrokeWidth: 3.5,
        circleStrokeColor: Colors.white.toARGB32(),
      ),
    );
  }

  void _fitCameraToCoverage({bool animate = false}) {
    final map = _mapboxMap;
    if (map == null) return;

    final camera = CameraOptions(
      center: Point(coordinates: Position(_centerLng, _centerLat)),
      zoom: _zoomForRadiusKm(_radiusKm),
    );

    if (animate) {
      map.flyTo(
        camera,
        MapAnimationOptions(duration: 700, startDelay: 0),
      );
    } else {
      map.setCamera(camera);
    }
  }

  void _setRadiusKm(double km) {
    final clamped = km.clamp(_minRadiusKm, _maxRadiusKm);
    if (clamped == _radiusKm) return;
    setState(() => _radiusKm = clamped);
    HapticService.light();
    _syncMapVisuals();
  }

  void _confirm() {
    HapticService.medium();
    Navigator.pop(
      context,
      ServiceAreaMapPickResult(
        lat: _centerLat,
        lng: _centerLng,
        radiusKm: _radiusKm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('serviceAreaCoverageMap'),
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(_centerLng, _centerLat)),
              zoom: _zoomForRadiusKm(_radiusKm),
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
                _IconButton(
                  icon: Icons.close_rounded,
                  onTap: () {
                    HapticService.light();
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoBanner(
                    lat: _centerLat,
                    lng: _centerLng,
                    radiusKm: _radiusKm,
                    isLocating: _isLocating,
                  ),
                ),
              ],
            ),
          ),
          if (_isLocating)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surface.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: palette.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Getting your location…',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: bottom + 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MyLocationButton(
                  isLocating: _isLocating,
                  onTap: () => unawaited(_goToMyLocation()),
                ),
                const SizedBox(height: 12),
                _RadiusPanel(
                  radiusKm: _radiusKm,
                  presets: _radiusPresets,
                  minKm: _minRadiusKm,
                  maxKm: _maxRadiusKm,
                  onPreset: _setRadiusKm,
                  onSlider: _setRadiusKm,
                  onConfirm: _confirm,
                  theme: theme,
                  palette: palette,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Geographic ring for [radiusKm] around ([lat], [lng]).
List<Position> _circleRing(double lat, double lng, double radiusKm) {
  const segments = 64;
  const earthRadiusKm = 6371.0;
  final latRad = lat * math.pi / 180;
  final lngRad = lng * math.pi / 180;
  final angular = radiusKm / earthRadiusKm;

  final ring = <Position>[];
  for (var i = 0; i <= segments; i++) {
    final bearing = 2 * math.pi * i / segments;
    final lat2 = math.asin(
      math.sin(latRad) * math.cos(angular) +
          math.cos(latRad) * math.sin(angular) * math.cos(bearing),
    );
    final lng2 = lngRad +
        math.atan2(
          math.sin(bearing) * math.sin(angular) * math.cos(latRad),
          math.cos(angular) - math.sin(latRad) * math.sin(lat2),
        );
    ring.add(Position(lng2 * 180 / math.pi, lat2 * 180 / math.pi));
  }
  return ring;
}

double _zoomForRadiusKm(double radiusKm) {
  if (radiusKm <= 5) return 11.8;
  if (radiusKm <= 10) return 10.8;
  if (radiusKm <= 15) return 10.2;
  if (radiusKm <= 20) return 9.7;
  return 9.2;
}

/// Recenters coverage circle + camera on the user's current GPS.
class _MyLocationButton extends StatelessWidget {
  final bool isLocating;
  final VoidCallback onTap;

  const _MyLocationButton({
    required this.isLocating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Tooltip(
      message: 'Center coverage on my location',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocating ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: palette.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: palette.primary.withValues(alpha: 0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: isLocating
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

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
            color: palette.surface.withValues(alpha: 0.94),
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
          child: Icon(icon, size: 22, color: palette.textPrimary),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final double lat;
  final double lng;
  final double radiusKm;
  final bool isLocating;

  const _InfoBanner({
    required this.lat,
    required this.lng,
    required this.radiusKm,
    required this.isLocating,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.94),
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
          Icon(Icons.touch_app_rounded, color: palette.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLocating
                      ? 'Centering on your GPS location…'
                      : 'Blue dot = you · tap map to move · target = center circle on you',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${radiusKm.round()} km radius · ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
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

class _RadiusPanel extends StatelessWidget {
  final double radiusKm;
  final List<int> presets;
  final double minKm;
  final double maxKm;
  final ValueChanged<double> onPreset;
  final ValueChanged<double> onSlider;
  final VoidCallback onConfirm;
  final ThemeData theme;
  final AppColors palette;

  const _RadiusPanel({
    required this.radiusKm,
    required this.presets,
    required this.minKm,
    required this.maxKm,
    required this.onPreset,
    required this.onSlider,
    required this.onConfirm,
    required this.theme,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.adjust_rounded, color: palette.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Coverage radius',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(
                    alpha: palette.isDark ? 0.25 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${radiusKm.round()} km',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: palette.primary,
              inactiveTrackColor: palette.border,
              thumbColor: palette.primary,
              overlayColor: palette.primary.withValues(alpha: 0.12),
              trackHeight: 5,
            ),
            child: Slider(
              value: radiusKm,
              min: minKm,
              max: maxKm,
              divisions: 22,
              label: '${radiusKm.round()} km',
              onChanged: onSlider,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: presets.map((km) {
              final selected = radiusKm.round() == km;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onPreset(km.toDouble()),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? palette.primary
                              : palette.surfaceInset,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? palette.primary
                                : palette.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$km km',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? Colors.white
                                  : palette.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text('Confirm coverage'),
            style: FilledButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
