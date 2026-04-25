import 'package:equatable/equatable.dart';

class HelperLocation extends Equatable {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final DateTime timestamp;

  const HelperLocation({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [latitude, longitude, heading, speed, timestamp];
}

class LocationStatus extends Equatable {
  final bool isOnline;
  final DateTime? lastUpdate;
  final int secondsSinceLastUpdate;
  final bool isFresh;
  final List<String> warnings;

  const LocationStatus({
    required this.isOnline,
    this.lastUpdate,
    required this.secondsSinceLastUpdate,
    required this.isFresh,
    required this.warnings,
  });

  @override
  List<Object?> get props => [isOnline, lastUpdate, secondsSinceLastUpdate, isFresh, warnings];
}

class InstantEligibility extends Equatable {
  final bool isEligible;
  final List<EligibilityWarning> warnings;
  final Map<String, dynamic> debugInfo;

  const InstantEligibility({
    required this.isEligible,
    required this.warnings,
    required this.debugInfo,
  });

  @override
  List<Object?> get props => [isEligible, warnings, debugInfo];
}

class EligibilityWarning extends Equatable {
  final String code;
  final String message;
  final String severity; // 'critical', 'warning', 'info'

  const EligibilityWarning({
    required this.code,
    required this.message,
    required this.severity,
  });

  @override
  List<Object?> get props => [code, message, severity];
}
