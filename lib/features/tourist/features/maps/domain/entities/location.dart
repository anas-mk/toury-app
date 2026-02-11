import 'package:equatable/equatable.dart';

/// Domain Entity - Location
/// يمثل موقع جغرافي (نقطة على الخريطة)
class Location extends Equatable {
  final double latitude;
  final double longitude;
  final String? name;
  final String? address;

  const Location({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, name, address];

  @override
  String toString() {
    return 'Location(lat: $latitude, lon: $longitude, name: $name)';
  }
}