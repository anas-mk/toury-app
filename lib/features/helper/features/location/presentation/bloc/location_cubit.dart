import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit() : super(LocationInitial());

  StreamSubscription<Position>? _positionSubscription;
  
  // Adaptive Tracking Memory
  Position? _lastBroadcastPosition;
  DateTime? _lastBroadcastTime;

  void startTracking() async {
    // 1. Check Permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(const LocationError('Location services are disabled.'));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        emit(const LocationError('Location permissions are denied.'));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      emit(const LocationError('Location permissions are permanently denied.'));
      return;
    }

    // 2. Start High-Accuracy Stream
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // 0 allows high-fps UI rendering, we filter manually for the backend
      ),
    ).listen((Position position) {
      _processLocationUpdate(position);
    });
  }

  void _processLocationUpdate(Position position) {
    // A. Emit immediately for smooth Map/UI Marker movement (60fps)
    emit(LocationTracking(
      currentPosition: LatLng(position.latitude, position.longitude),
      heading: position.heading,
      speed: position.speed,
    ));

    // B. Adaptive Tracking Logic (deciding when to send to backend)
    _evaluateForBackendBroadcast(position);
  }

  void _evaluateForBackendBroadcast(Position currentPosition) {
    if (_lastBroadcastPosition == null || _lastBroadcastTime == null) {
      _broadcastToBackend(currentPosition);
      return;
    }

    final distanceDelta = Geolocator.distanceBetween(
      _lastBroadcastPosition!.latitude,
      _lastBroadcastPosition!.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    final headingDelta = (currentPosition.heading - _lastBroadcastPosition!.heading).abs();
    final timeDelta = DateTime.now().difference(_lastBroadcastTime!).inSeconds;

    // ADAPTIVE ALGORITHM: Send update if distance > 5m OR heading > 15 deg OR time > 3s
    if (distanceDelta > 5.0 || headingDelta > 15.0 || timeDelta > 3) {
      _broadcastToBackend(currentPosition);
    }
  }

  void _broadcastToBackend(Position position) {
    _lastBroadcastPosition = position;
    _lastBroadcastTime = DateTime.now();
    // In future step: Push to WebSockets/Firebase here.
    print('LocationCubit [BACKEND BROADCAST] -> Lat: ${position.latitude}, Lng: ${position.longitude}, Heading: ${position.heading}');
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    emit(LocationInitial());
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }
}
