import 'package:equatable/equatable.dart';
import 'location.dart';

/// Domain Entity - Route
/// يمثل مسار بين نقطتين
class RouteInfo extends Equatable {
  final Location start;
  final Location destination;
  final List<Location> points;
  final double distanceInKm;
  final double durationInMinutes;

  const RouteInfo({
    required this.start,
    required this.destination,
    required this.points,
    required this.distanceInKm,
    required this.durationInMinutes,
  });

  @override
  List<Object?> get props => [
    start,
    destination,
    points,
    distanceInKm,
    durationInMinutes,
  ];

  @override
  String toString() {
    return 'RouteInfo(distance: ${distanceInKm.toStringAsFixed(2)} km, '
        'duration: ${durationInMinutes.toStringAsFixed(0)} min)';
  }
}