import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/repositories/location_repository.dart';
import 'trip_state.dart';

/// Trip Cubit - إدارة حالة الرحلة النشطة
class TripCubit extends Cubit<TripState> {
  final LocationRepository locationRepository;
  StreamSubscription<Location>? _locationSubscription;

  Location? _previousLocation;
  double _traveledDistance = 0;

  TripCubit({required this.locationRepository})
      : super(TripInProgress(
    currentLocation: const Location(latitude: 0, longitude: 0),
    route: const RouteInfo(
      start: Location(latitude: 0, longitude: 0),
      destination: Location(latitude: 0, longitude: 0),
      points: [],
      distanceInKm: 0,
      durationInMinutes: 0,
    ),
    remainingDistance: 0,
    remainingDuration: 0,
    traveledDistance: 0,
    instruction: 'Starting trip...',
  ));

  /// بدء تتبع الرحلة
  void startTrip(RouteInfo route) {
    // تهيئة الحالة الأولية
    _previousLocation = route.start;
    _traveledDistance = 0;

    emit(TripInProgress(
      currentLocation: route.start,
      route: route,
      remainingDistance: route.distanceInKm,
      remainingDuration: route.durationInMinutes,
      traveledDistance: 0,
      instruction: 'Starting trip...',
    ));

    // بدء الاستماع للموقع
    _startLocationTracking();
  }

  /// بدء تتبع الموقع
  void _startLocationTracking() {
    _locationSubscription =
        locationRepository.watchCurrentLocation().listen((location) {
          _onLocationUpdate(location);
        });
  }

  /// تحديث الموقع
  void _onLocationUpdate(Location newLocation) {
    final currentState = state;
    if (currentState is! TripInProgress) return;

    // حساب المسافة المقطوعة
    if (_previousLocation != null) {
      final distance = Geolocator.distanceBetween(
        _previousLocation!.latitude,
        _previousLocation!.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );

      _traveledDistance += distance / 1000; // تحويل لكيلومتر
    }

    _previousLocation = newLocation;

    // حساب المسافة المتبقية
    final distanceToDestination = Geolocator.distanceBetween(
      newLocation.latitude,
      newLocation.longitude,
      currentState.route.destination.latitude,
      currentState.route.destination.longitude,
    ) / 1000;

    // تقدير الوقت المتبقي (بناءً على سرعة متوسطة 40 كم/س)
    final remainingDuration = (distanceToDestination / 40) * 60; // بالدقائق

    // تحديث التعليمات
    final instruction = _getInstruction(distanceToDestination);

    // التحقق من الوصول
    if (distanceToDestination < 0.05) {
      // 50 متر
      _arrivedAtDestination();
      return;
    }

    // تحديث الحالة
    emit(currentState.copyWith(
      currentLocation: newLocation,
      remainingDistance: distanceToDestination,
      remainingDuration: remainingDuration,
      traveledDistance: _traveledDistance,
      instruction: instruction,
    ));
  }

  /// الحصول على التعليمات بناءً على المسافة
  String _getInstruction(double distance) {
    if (distance < 0.1) {
      return "You have arrived!";
    } else if (distance < 0.5) {
      return "Destination is near";
    } else {
      return "Continue straight";
    }
  }

  /// الوصول للوجهة
  void _arrivedAtDestination() {
    _locationSubscription?.cancel();
    emit(TripCompleted(_traveledDistance));
  }

  /// إلغاء الرحلة
  void cancelTrip() {
    _locationSubscription?.cancel();
    emit(TripCancelled());
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}