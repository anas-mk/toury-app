import 'package:equatable/equatable.dart';

class HelperLocation extends Equatable {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speedKmh;
  final double? accuracyMeters;
  final DateTime timestamp;

  const HelperLocation({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speedKmh,
    this.accuracyMeters,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [latitude, longitude, heading, speedKmh, accuracyMeters, timestamp];
}

class LocationUpdateResponse extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime updatedAt;
  final bool isLocationFresh;
  final String availabilityState;
  final bool canReceiveInstantRequests;

  const LocationUpdateResponse({
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    required this.isLocationFresh,
    required this.availabilityState,
    required this.canReceiveInstantRequests,
  });

  @override
  List<Object?> get props => [latitude, longitude, updatedAt, isLocationFresh, availabilityState, canReceiveInstantRequests];
}

class LocationStatus extends Equatable {
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? currentLocationUpdatedAt;
  final bool isLocationFresh;
  final int secondsSinceLastUpdate;
  final String availabilityState;
  final bool canReceiveInstantRequests;
  final double? defaultLatitude;
  final double? defaultLongitude;
  final double defaultRadiusKm;
  final int recommendedUpdateIntervalSeconds;
  final int freshnessThresholdMinutes;
  final double effectiveInstantRadiusKm;
  final List<String> eligibilityWarnings;

  const LocationStatus({
    this.currentLatitude,
    this.currentLongitude,
    this.currentLocationUpdatedAt,
    required this.isLocationFresh,
    required this.secondsSinceLastUpdate,
    required this.availabilityState,
    required this.canReceiveInstantRequests,
    this.defaultLatitude,
    this.defaultLongitude,
    required this.defaultRadiusKm,
    required this.recommendedUpdateIntervalSeconds,
    required this.freshnessThresholdMinutes,
    required this.effectiveInstantRadiusKm,
    required this.eligibilityWarnings,
  });

  @override
  List<Object?> get props => [
        currentLatitude,
        currentLongitude,
        currentLocationUpdatedAt,
        isLocationFresh,
        secondsSinceLastUpdate,
        availabilityState,
        canReceiveInstantRequests,
        defaultLatitude,
        defaultLongitude,
        defaultRadiusKm,
        recommendedUpdateIntervalSeconds,
        freshnessThresholdMinutes,
        effectiveInstantRadiusKm,
        eligibilityWarnings,
      ];
}

class InstantEligibility extends Equatable {
  final bool isEligible;
  final List<String> eligibilityWarnings;
  final Map<String, dynamic>? debugDetails;

  const InstantEligibility({
    required this.isEligible,
    required this.eligibilityWarnings,
    this.debugDetails,
  });

  @override
  List<Object?> get props => [isEligible, eligibilityWarnings, debugDetails];
}
