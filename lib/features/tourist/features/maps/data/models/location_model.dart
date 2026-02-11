import '../../domain/entities/location.dart';

/// Data Model - Location
/// يتعامل مع تحويل البيانات من/إلى JSON
class LocationModel extends Location {
  const LocationModel({
    required super.latitude,
    required super.longitude,
    super.name,
    super.address,
  });

  /// من JSON
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: _parseDouble(json['lat'] ?? json['latitude']),
      longitude: _parseDouble(json['lon'] ?? json['longitude']),
      name: json['name'] as String?,
      address: json['display_name'] as String? ?? json['address'] as String?,
    );
  }

  /// إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'address': address,
    };
  }

  /// من Domain Entity
  factory LocationModel.fromEntity(Location location) {
    return LocationModel(
      latitude: location.latitude,
      longitude: location.longitude,
      name: location.name,
      address: location.address,
    );
  }

  /// تحويل آمن من String إلى double
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}