import 'package:equatable/equatable.dart';

class ServiceAreaEntity extends Equatable {
  final String id;
  final String country;
  final String city;
  final String? areaName;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final bool isPrimary;
  final DateTime? createdAt;

  const ServiceAreaEntity({
    required this.id,
    required this.country,
    required this.city,
    this.areaName,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.isPrimary,
    this.createdAt,
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
        createdAt,
      ];

  ServiceAreaEntity copyWith({
    String? id,
    String? country,
    String? city,
    String? areaName,
    double? latitude,
    double? longitude,
    double? radiusKm,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return ServiceAreaEntity(
      id: id ?? this.id,
      country: country ?? this.country,
      city: city ?? this.city,
      areaName: areaName ?? this.areaName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
