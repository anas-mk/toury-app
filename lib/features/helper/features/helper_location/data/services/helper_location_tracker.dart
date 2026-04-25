import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/helper_location_models.dart';

class HelperLocationTracker {
  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<HelperLocationModel>.broadcast();
  Stream<HelperLocationModel> get locationStream => _locationController.stream;

  Future<bool> checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<void> startTracking({int intervalSeconds = 10}) async {
    final hasPermission = await checkPermission();
    if (!hasPermission) throw Exception('Location permission denied');

    // Ensure previous subscription is cancelled before starting a new one
    await stopTracking();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Increased threshold for better battery and less spam
        intervalDuration: Duration(seconds: intervalSeconds),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Toury is tracking your location to match you with travelers.",
          notificationTitle: "Location Tracking Active",
          enableWakeLock: true,
        ),
      ),
    ).listen(
      (Position position) {
        if (_locationController.isClosed) return;
        _locationController.add(HelperLocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          heading: position.heading,
          speed: position.speed,
          timestamp: DateTime.now(),
        ));
      },
      onError: (error) {
        // Handle stream errors
      },
      cancelOnError: false,
    );
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<HelperLocationModel> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return HelperLocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      heading: position.heading,
      speed: position.speed,
      timestamp: DateTime.now(),
    );
  }

  void dispose() {
    stopTracking();
    if (!_locationController.isClosed) {
      _locationController.close();
    }
  }
}
