import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// One-shot fetch result types (used by LocationCubit)
// ─────────────────────────────────────────────────────────────────────────────

sealed class LocationResult {
  const LocationResult();
}

class LocationSuccess extends LocationResult {
  final double latitude;
  final double longitude;
  final double? accuracy;
  const LocationSuccess({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });
}

class LocationPermissionDenied extends LocationResult {
  const LocationPermissionDenied();
}

class LocationPermissionPermanentlyDenied extends LocationResult {
  const LocationPermissionPermanentlyDenied();
}

class LocationServiceDisabled extends LocationResult {
  const LocationServiceDisabled();
}

class LocationError extends LocationResult {
  final String message;
  const LocationError(this.message);
}

/// Single GPS session for the whole app.
///
/// Contract:
/// - Only this class may call [Geolocator.getPositionStream].
/// - Safe to call [startTracking] multiple times (idempotent).
/// - Exposes a broadcast stream any feature can listen to.
class LocationService {
  LocationService._internal();

  /// Keep existing code that does `LocationService()` working by returning
  /// the singleton instance.
  factory LocationService() => instance;

  static final LocationService instance = LocationService._internal();

  StreamSubscription<Position>? _positionSubscription;
  final StreamController<Position> _locationController = StreamController<Position>.broadcast();

  // Stream emission throttling (for local listeners, not the backend).
  Position? _lastEmittedPosition;
  DateTime? _lastEmitTime;
  
  static const Duration _throttleDuration = Duration(seconds: 3); // Production Uber-like interval
  static const double _minDistanceFilter = 5.0; // Meters

  /// Stream that UI and other services should listen to.
  Stream<Position> get positionStream => _locationController.stream;

  /// Check and request location permissions.
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// One-shot location fetch used by `LocationCubit`.
  ///
  /// Important: this does NOT start the continuous stream.
  Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return const LocationServiceDisabled();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationPermissionDenied();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationPermissionPermanentlyDenied();
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return LocationSuccess(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy.isNaN ? null : pos.accuracy,
      );
    } catch (e) {
      return LocationError(e.toString());
    }
  }

  bool get isTracking => _positionSubscription != null;

  /// Start tracking location with optimized settings.
  /// 
  /// This method is safe to call multiple times; it will only create 
  /// ONE subscription to the underlying [Geolocator].
  Future<void> startTracking() async {
    if (_positionSubscription != null) {
      debugPrint('[LocationService] Already tracking. Skipping start.');
      return;
    }

    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      debugPrint('[LocationService] Permission denied. Cannot start tracking.');
      return;
    }

    debugPrint('[LocationService] Starting location stream...');
    
    final settings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _minDistanceFilter.toInt(),
      intervalDuration: _throttleDuration,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "Tracking your location to match you with travelers.",
        notificationTitle: "Location Active",
        enableWakeLock: true,
      ),
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: defaultTargetPlatform == TargetPlatform.android
          ? settings
          : const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen(
      _handlePositionUpdate,
      onError: (e) => debugPrint('[LocationService] Error in stream: $e'),
      cancelOnError: false,
    );
  }

  /// Internal handler with throttling logic.
  void _handlePositionUpdate(Position position) {
    if (_locationController.isClosed) return;

    final now = DateTime.now();
    
    // Throttling Logic:
    // 1. Time check (Uber-like apps usually update every 3-5s)
    if (_lastEmitTime != null && now.difference(_lastEmitTime!) < _throttleDuration) {
      return;
    }

    // 2. Significant movement check (prevents jitter when stationary)
    if (_lastEmittedPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastEmittedPosition!.latitude,
        _lastEmittedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      
      // If moved less than threshold and time since last update is small, ignore
      if (distance < _minDistanceFilter && now.difference(_lastEmitTime!) < const Duration(seconds: 10)) {
        return;
      }
    }

    _lastEmittedPosition = position;
    _lastEmitTime = now;
    _locationController.add(position);
    
    debugPrint('[LocationService] Lat: ${position.latitude}, Lng: ${position.longitude}');
  }

  /// Stop tracking and cleanup subscription.
  Future<void> stopTracking() async {
    debugPrint('[LocationService] Stopping tracking.');
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastEmittedPosition = null;
    _lastEmitTime = null;
  }

  /// Useful for immediate fetch before starting stream.
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return null;
    
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Full cleanup.
  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
