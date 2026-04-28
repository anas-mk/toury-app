import 'package:equatable/equatable.dart';

abstract class LocationState extends Equatable {
  const LocationState();
  @override
  List<Object?> get props => [];
}

/// Not yet attempted.
class LocationInitial extends LocationState {}

/// Fetching GPS coordinates.
class LocationLoading extends LocationState {}

/// Coordinates are available and ready to use.
class LocationReady extends LocationState {
  final double latitude;
  final double longitude;
  final double? accuracy;

  const LocationReady({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  @override
  List<Object?> get props => [latitude, longitude, accuracy];
}

/// User denied permission (but can still be asked again).
class LocationPermissionDeniedState extends LocationState {}

/// User permanently denied — must open app settings.
class LocationPermissionPermanentlyDeniedState extends LocationState {}

/// Device GPS is turned off.
class LocationServiceDisabledState extends LocationState {}

/// Any other error (timeout, hardware failure, etc.).
class LocationErrorState extends LocationState {
  final String message;
  const LocationErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
