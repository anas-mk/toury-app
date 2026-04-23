class HelperLocationUpdate {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speedKmh;
  final double? accuracyMeters;

  HelperLocationUpdate({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speedKmh,
    this.accuracyMeters,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speedKmh': speedKmh,
        'accuracyMeters': accuracyMeters,
      };
}

class HelperLocationStatus {
  final String availabilityState;
  final String freshness;
  final bool canReceiveInstantRequests;
  final int recommendedUpdateIntervalSeconds;
  final List<String> warnings;

  HelperLocationStatus({
    required this.availabilityState,
    required this.freshness,
    required this.canReceiveInstantRequests,
    required this.recommendedUpdateIntervalSeconds,
    required this.warnings,
  });

  factory HelperLocationStatus.fromJson(Map<String, dynamic> json) {
    return HelperLocationStatus(
      availabilityState: json['availabilityState'] ?? 'Offline',
      freshness: json['freshness'] ?? 'Unknown',
      canReceiveInstantRequests: json['canReceiveInstantRequests'] ?? false,
      recommendedUpdateIntervalSeconds: json['recommendedUpdateIntervalSeconds'] ?? 30,
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }
}

class InstantEligibilityRule {
  final String name;
  final bool passed;
  final String? message;

  InstantEligibilityRule({
    required this.name,
    required this.passed,
    this.message,
  });

  factory InstantEligibilityRule.fromJson(Map<String, dynamic> json) {
    return InstantEligibilityRule(
      name: json['name'] ?? '',
      passed: json['passed'] ?? false,
      message: json['message'],
    );
  }
}

class InstantEligibility {
  final List<InstantEligibilityRule> rules;
  final bool finalEligible;

  InstantEligibility({
    required this.rules,
    required this.finalEligible,
  });

  factory InstantEligibility.fromJson(Map<String, dynamic> json) {
    return InstantEligibility(
      rules: (json['rules'] as List? ?? []).map((r) => InstantEligibilityRule.fromJson(r)).toList(),
      finalEligible: json['finalEligible'] ?? false,
    );
  }
}
