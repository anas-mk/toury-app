import 'package:equatable/equatable.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/route_info.dart';

/// Trip State - حالات الرحلة النشطة
abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية - الرحلة نشطة
class TripInProgress extends TripState {
  final Location currentLocation;
  final RouteInfo route;
  final double remainingDistance;
  final double remainingDuration;
  final double traveledDistance;
  final String instruction;

  const TripInProgress({
    required this.currentLocation,
    required this.route,
    required this.remainingDistance,
    required this.remainingDuration,
    required this.traveledDistance,
    required this.instruction,
  });

  @override
  List<Object?> get props => [
    currentLocation,
    route,
    remainingDistance,
    remainingDuration,
    traveledDistance,
    instruction,
  ];

  TripInProgress copyWith({
    Location? currentLocation,
    RouteInfo? route,
    double? remainingDistance,
    double? remainingDuration,
    double? traveledDistance,
    String? instruction,
  }) {
    return TripInProgress(
      currentLocation: currentLocation ?? this.currentLocation,
      route: route ?? this.route,
      remainingDistance: remainingDistance ?? this.remainingDistance,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      traveledDistance: traveledDistance ?? this.traveledDistance,
      instruction: instruction ?? this.instruction,
    );
  }
}

/// تم إكمال الرحلة
class TripCompleted extends TripState {
  final double totalDistance;

  const TripCompleted(this.totalDistance);

  @override
  List<Object?> get props => [totalDistance];
}

/// تم إلغاء الرحلة
class TripCancelled extends TripState {}