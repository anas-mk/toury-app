import '../../domain/entities/service_area_entity.dart';

/// [ServiceAreaModel] extends [ServiceAreaEntity] and handles JSON serialization.
/// Used in the Data layer to interact with the API.
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
  });

  factory ServiceAreaModel.fromJson(Map<String, dynamic> json) {
    // Support both flat responses and {data: {...}} wrapped responses.
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return ServiceAreaModel(
      id: data['id']?.toString() ?? '',
      country: data['country'] as String? ?? '',
      city: data['city'] as String? ?? '',
      areaName: data['areaName'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusKm: (data['radiusKm'] as num?)?.toDouble() ?? 0.0,
      isPrimary: data['isPrimary'] as bool? ?? false,
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

  /// Create a copy of this model with some properties changed.
  ServiceAreaModel copyWith({
    String? id,
    String? country,
    String? city,
    String? areaName,
    double? latitude,
    double? longitude,
    double? radiusKm,
    bool? isPrimary,
  }) {
    return ServiceAreaModel(
      id: id ?? this.id,
      country: country ?? this.country,
      city: city ?? this.city,
      areaName: areaName ?? this.areaName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
