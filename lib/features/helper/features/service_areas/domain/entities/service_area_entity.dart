import 'package:equatable/equatable.dart';

/// [ServiceAreaEntity] represents a geographic area where a helper operates.
/// This is used for scheduled bookings matching.
class ServiceAreaEntity extends Equatable {
  final String id;
  final String country;
  final String city;
  final String? areaName;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final bool isPrimary;

  const ServiceAreaEntity({
    required this.id,
    required this.country,
    required this.city,
    this.areaName,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.isPrimary,
  });

  @override
  List<Object?> get props => [
        id,
        country,
        city,
        areaName,
        latitude,
        longitude,
        radiusKm,
        isPrimary,
      ];
}
