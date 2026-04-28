import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Result of a location request — clean sealed-like class.
sealed class LocationResult {}

class LocationSuccess extends LocationResult {
  final double latitude;
  final double longitude;
  final double? accuracy;
  LocationSuccess({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });
}

class LocationPermissionDenied extends LocationResult {}

class LocationPermissionPermanentlyDenied extends LocationResult {}

class LocationServiceDisabled extends LocationResult {}

class LocationError extends LocationResult {
  final String message;
  LocationError(this.message);
}

/// Pure service — no Flutter state, no UI. Usable from any cubit/usecase.
class LocationService {
  static const LocationSettings _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // metres — only push update if user moved 10m
    timeLimit: Duration(seconds: 10),
  );

  /// Request permissions and then return the current position.
  Future<LocationResult> getCurrentLocation() async {
    // 1. Is GPS hardware enabled?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[LocationService] GPS service is disabled.');
      return LocationServiceDisabled();
    }

    // 2. Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[LocationService] Permission denied by user.');
        return LocationPermissionDenied();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[LocationService] Permission permanently denied.');
      return LocationPermissionPermanentlyDenied();
    }

    // 3. Fetch position
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      );
      debugPrint(
        '[LocationService] Got position: lat=${position.latitude}, '
        'lng=${position.longitude}, accuracy=${position.accuracy}m',
      );
      return LocationSuccess(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (e) {
      debugPrint('[LocationService] Error fetching position: $e');
      return LocationError(e.toString());
    }
  }

  /// Returns a stream of position updates (useful for live tracking).
  Stream<Position> get positionStream =>
      Geolocator.getPositionStream(locationSettings: _settings);
}
