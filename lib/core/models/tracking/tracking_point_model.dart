import 'tracking_point_entity.dart';

/// Helper for safely casting a numeric JSON field that might come in as
/// `int`, `double`, or `String`.
double? _readDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _readInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

class TrackingPointModel extends TrackingPointEntity {
  const TrackingPointModel({
    required super.latitude,
    required super.longitude,
    super.heading,
    super.speed,
    required super.timestamp,
    super.distanceToPickupKm,
    super.etaToPickupMinutes,
    super.distanceToDestinationKm,
    super.etaToDestinationMinutes,
    super.phase,
  });

  factory TrackingPointModel.fromJson(Map<String, dynamic> json) {
    // The same payload shape ships from REST `/tracking/latest` and
    // from the SignalR `HelperLocationUpdate` event. We accept both
    // `timestamp` and `capturedAt` so the model is forgiving across
    // versions.
    final tsRaw = json['timestamp'] ?? json['capturedAt'];
    return TrackingPointModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      heading: _readDouble(json['heading']),
      speed: _readDouble(json['speed'] ?? json['speedKmh']),
      timestamp: tsRaw != null
          ? DateTime.parse(tsRaw.toString())
          : DateTime.now().toUtc(),
      distanceToPickupKm: _readDouble(json['distanceToPickupKm']),
      etaToPickupMinutes: _readInt(json['etaToPickupMinutes']),
      distanceToDestinationKm: _readDouble(json['distanceToDestinationKm']),
      etaToDestinationMinutes: _readInt(json['etaToDestinationMinutes']),
      phase: json['phase']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
      'distanceToPickupKm': distanceToPickupKm,
      'etaToPickupMinutes': etaToPickupMinutes,
      'distanceToDestinationKm': distanceToDestinationKm,
      'etaToDestinationMinutes': etaToDestinationMinutes,
      'phase': phase,
    };
  }
}
