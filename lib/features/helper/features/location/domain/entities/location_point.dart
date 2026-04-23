import 'package:equatable/equatable.dart';

class LocationPoint extends Equatable {
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final DateTime timestamp;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speed,
    required this.timestamp,
  });

  LocationPoint copyWith({
    double? latitude,
    double? longitude,
    double? heading,
    double? speed,
    DateTime? timestamp,
  }) {
    return LocationPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, heading, speed, timestamp];
}
