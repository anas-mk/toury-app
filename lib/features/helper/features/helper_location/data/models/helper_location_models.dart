import '../../domain/entities/helper_location_entities.dart';

class HelperLocationModel extends HelperLocation {
  const HelperLocationModel({
    required super.latitude,
    required super.longitude,
    super.bookingId,
    super.heading,
    super.speedKmh,
    super.accuracyMeters,
    required super.timestamp,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speedKmh': speedKmh,
      'accuracyMeters': accuracyMeters,
    };
    if (bookingId != null) {
      map['bookingId'] = bookingId;
    }
    return map;
  }

  factory HelperLocationModel.fromEntity(HelperLocation entity) {
    return HelperLocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      bookingId: entity.bookingId,
      heading: entity.heading,
      speedKmh: entity.speedKmh,
      accuracyMeters: entity.accuracyMeters,
      timestamp: entity.timestamp,
    );
  }
}

class LocationUpdateResponseModel extends LocationUpdateResponse {
  const LocationUpdateResponseModel({
    required super.latitude,
    required super.longitude,
    required super.updatedAt,
    required super.isLocationFresh,
    required super.availabilityState,
    required super.canReceiveInstantRequests,
  });

  factory LocationUpdateResponseModel.fromJson(Map<String, dynamic> json) {
    return LocationUpdateResponseModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt']),
      isLocationFresh: json['isLocationFresh'] ?? false,
      availabilityState: json['availabilityState'] ?? '',
      canReceiveInstantRequests: json['canReceiveInstantRequests'] ?? false,
    );
  }
}

class LocationStatusModel extends LocationStatus {
  const LocationStatusModel({
    super.currentLatitude,
    super.currentLongitude,
    super.currentLocationUpdatedAt,
    required super.isLocationFresh,
    required super.secondsSinceLastUpdate,
    required super.availabilityState,
    required super.canReceiveInstantRequests,
    super.defaultLatitude,
    super.defaultLongitude,
    required super.defaultRadiusKm,
    required super.recommendedUpdateIntervalSeconds,
    required super.freshnessThresholdMinutes,
    required super.effectiveInstantRadiusKm,
    required super.eligibilityWarnings,
  });

  factory LocationStatusModel.fromJson(Map<String, dynamic> json) {
    return LocationStatusModel(
      currentLatitude: (json['currentLatitude'] as num?)?.toDouble(),
      currentLongitude: (json['currentLongitude'] as num?)?.toDouble(),
      currentLocationUpdatedAt: json['currentLocationUpdatedAt'] != null 
          ? DateTime.parse(json['currentLocationUpdatedAt']) 
          : null,
      isLocationFresh: json['isLocationFresh'] ?? false,
      secondsSinceLastUpdate: json['secondsSinceLastUpdate'] ?? 0,
      availabilityState: json['availabilityState'] ?? '',
      canReceiveInstantRequests: json['canReceiveInstantRequests'] ?? false,
      defaultLatitude: (json['defaultLatitude'] as num?)?.toDouble(),
      defaultLongitude: (json['defaultLongitude'] as num?)?.toDouble(),
      defaultRadiusKm: (json['defaultRadiusKm'] as num? ?? 0).toDouble(),
      recommendedUpdateIntervalSeconds: json['recommendedUpdateIntervalSeconds'] ?? 30,
      freshnessThresholdMinutes: json['freshnessThresholdMinutes'] ?? 5,
      effectiveInstantRadiusKm: (json['effectiveInstantRadiusKm'] as num? ?? 0).toDouble(),
      eligibilityWarnings: List<String>.from(json['eligibilityWarnings'] ?? []),
    );
  }
}

class InstantEligibilityModel extends InstantEligibility {
  const InstantEligibilityModel({
    required super.isEligible,
    required super.eligibilityWarnings,
    super.debugDetails,
  });

  factory InstantEligibilityModel.fromJson(Map<String, dynamic> json) {
    return InstantEligibilityModel(
      isEligible: json['isEligible'] ?? false,
      eligibilityWarnings: List<String>.from(json['eligibilityWarnings'] ?? []),
      debugDetails: json['debugDetails'],
    );
  }
}
