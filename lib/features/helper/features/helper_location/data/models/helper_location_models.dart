import '../../domain/entities/helper_location_entities.dart';

class HelperLocationModel extends HelperLocation {
  const HelperLocationModel({
    required super.latitude,
    required super.longitude,
    super.heading,
    super.speed,
    required super.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HelperLocationModel.fromEntity(HelperLocation entity) {
    return HelperLocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      heading: entity.heading,
      speed: entity.speed,
      timestamp: entity.timestamp,
    );
  }
}

class LocationStatusModel extends LocationStatus {
  const LocationStatusModel({
    required super.isOnline,
    super.lastUpdate,
    required super.secondsSinceLastUpdate,
    required super.isFresh,
    required super.warnings,
  });

  factory LocationStatusModel.fromJson(Map<String, dynamic> json) {
    return LocationStatusModel(
      isOnline: json['isOnline'] ?? false,
      lastUpdate: json['lastUpdate'] != null ? DateTime.parse(json['lastUpdate']) : null,
      secondsSinceLastUpdate: json['secondsSinceLastUpdate'] ?? 0,
      isFresh: json['isFresh'] ?? false,
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }
}

class InstantEligibilityModel extends InstantEligibility {
  const InstantEligibilityModel({
    required super.isEligible,
    required super.warnings,
    required super.debugInfo,
  });

  factory InstantEligibilityModel.fromJson(Map<String, dynamic> json) {
    return InstantEligibilityModel(
      isEligible: json['isEligible'] ?? false,
      warnings: (json['warnings'] as List? ?? [])
          .map((e) => EligibilityWarningModel.fromJson(e))
          .toList(),
      debugInfo: Map<String, dynamic>.from(json['debugInfo'] ?? {}),
    );
  }
}

class EligibilityWarningModel extends EligibilityWarning {
  const EligibilityWarningModel({
    required super.code,
    required super.message,
    required super.severity,
  });

  factory EligibilityWarningModel.fromJson(Map<String, dynamic> json) {
    return EligibilityWarningModel(
      code: json['code'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'info',
    );
  }
}
