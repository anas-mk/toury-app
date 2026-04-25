import '../../domain/entities/service_area_entities.dart';

class ServiceAreaModel extends ServiceAreaEntity {
  const ServiceAreaModel({
    required super.id,
    required super.country,
    required super.city,
    super.areaName,
    required super.latitude,
    required super.longitude,
    required super.radiusKm,
    required super.isPrimary,
    super.createdAt,
  });

  factory ServiceAreaModel.fromJson(Map<String, dynamic> json) {
    return ServiceAreaModel(
      id: json['id']?.toString() ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      areaName: json['areaName'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 0.0,
      isPrimary: json['isPrimary'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'city': city,
      'areaName': areaName,
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
      'isPrimary': isPrimary,
    };
  }

  factory ServiceAreaModel.fromEntity(ServiceAreaEntity entity) {
    return ServiceAreaModel(
      id: entity.id,
      country: entity.country,
      city: entity.city,
      areaName: entity.areaName,
      latitude: entity.latitude,
      longitude: entity.longitude,
      radiusKm: entity.radiusKm,
      isPrimary: entity.isPrimary,
      createdAt: entity.createdAt,
    );
  }
}
