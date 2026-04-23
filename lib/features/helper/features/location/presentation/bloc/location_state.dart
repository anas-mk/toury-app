import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

abstract class LocationState extends Equatable {
  const LocationState();
  
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationTracking extends LocationState {
  final LatLng currentPosition;
  final double heading;
  final double speed;

  const LocationTracking({
    required this.currentPosition,
    required this.heading,
    required this.speed,
  });

  @override
  List<Object?> get props => [currentPosition, heading, speed];
}

class LocationError extends LocationState {
  final String message;
  const LocationError(this.message);

  @override
  List<Object?> get props => [message];
}
