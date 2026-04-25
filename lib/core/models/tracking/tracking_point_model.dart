import 'tracking_point_entity.dart';

class TrackingPointModel extends TrackingPointEntity {
  const TrackingPointModel({
    required super.latitude,
    required super.longitude,
    super.heading,
    super.speed,
    required super.timestamp,
  });

  factory TrackingPointModel.fromJson(Map<String, dynamic> json) {
    return TrackingPointModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
