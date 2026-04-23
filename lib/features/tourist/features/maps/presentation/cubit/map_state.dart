import 'package:equatable/equatable.dart';

import '../../domain/entities/location.dart';
import '../../domain/entities/route_info.dart';
import '../../../../../../core/entities/location_entity.dart';

/// Map State - حالات الخريطة
abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class MapInitial extends MapState {}

/// Loading - جاري التحميل
class MapLoading extends MapState {}

/// Location Selected via tap for Booking Feature
class LocationSelected extends MapState {
  final LocationEntity location;

  const LocationSelected(this.location);

  @override
  List<Object?> get props => [location];
}

/// تم تحميل الموقع الحالي
class LocationLoaded extends MapState {
  final Location location;

  const LocationLoaded(this.location);

  @override
  List<Object?> get props => [location];
}

/// تم تحميل المسار
class RouteLoaded extends MapState {
  final Location currentLocation;
  final RouteInfo route;

  const RouteLoaded({
    required this.currentLocation,
    required this.route,
  });

  @override
  List<Object?> get props => [currentLocation, route];
}

/// Error - حدث خطأ
class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object?> get props => [message];
}

/// تم إلغاء المسار
class RouteCleared extends MapState {
  final Location currentLocation;

  const RouteCleared(this.currentLocation);

  @override
  List<Object?> get props => [currentLocation];
}