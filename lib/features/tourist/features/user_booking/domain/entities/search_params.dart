import 'package:equatable/equatable.dart';

class ScheduledSearchParams extends Equatable {
  final String destinationCity;
  final DateTime requestedDate;
  final String startTime;
  final int durationInMinutes;
  final String requestedLanguage;
  final bool requiresCar;
  final int travelersCount;

  // Destination geo-point. Required by the create endpoint, but the
  // search endpoint only consumes `destinationCity`. We carry the coords
  // through the flow so the booking-create call (POST /scheduled) has
  // them when we hit it after helper selection.
  final double? destinationLatitude;
  final double? destinationLongitude;

  // Optional pickup details captured up-front in the search form. All
  // three may be null — the user can leave them blank and add a pickup
  // later via chat.
  final String? pickupLocationName;
  final double? pickupLatitude;
  final double? pickupLongitude;

  const ScheduledSearchParams({
    required this.destinationCity,
    required this.requestedDate,
    required this.startTime,
    required this.durationInMinutes,
    required this.requestedLanguage,
    required this.requiresCar,
    required this.travelersCount,
    this.destinationLatitude,
    this.destinationLongitude,
    this.pickupLocationName,
    this.pickupLatitude,
    this.pickupLongitude,
  });

  @override
  List<Object?> get props => [
        destinationCity,
        requestedDate,
        startTime,
        durationInMinutes,
        requestedLanguage,
        requiresCar,
        travelersCount,
        destinationLatitude,
        destinationLongitude,
        pickupLocationName,
        pickupLatitude,
        pickupLongitude,
      ];

  /// Wire body for `POST /scheduled/search`. The search endpoint does
  /// not consume the geo-point fields — they live on this entity purely
  /// to pass through to the create call.
  Map<String, dynamic> toJson() => {
        'destinationCity': destinationCity,
        'requestedDate': requestedDate.toIso8601String(),
        'startTime': startTime,
        'durationInMinutes': durationInMinutes,
        'requestedLanguage': requestedLanguage,
        'requiresCar': requiresCar,
        'travelersCount': travelersCount,
      };
}

class InstantSearchParams extends Equatable {
  final String pickupLocationName;
  final double pickupLatitude;
  final double pickupLongitude;
  final int durationInMinutes;
  final String requestedLanguage;
  final bool requiresCar;
  final int travelersCount;

  const InstantSearchParams({
    required this.pickupLocationName,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.durationInMinutes,
    required this.requestedLanguage,
    required this.requiresCar,
    required this.travelersCount,
  });

  @override
  List<Object?> get props => [
        pickupLocationName,
        pickupLatitude,
        pickupLongitude,
        durationInMinutes,
        requestedLanguage,
        requiresCar,
        travelersCount,
      ];

  Map<String, dynamic> toJson() => {
        'pickupLocationName': pickupLocationName,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'durationInMinutes': durationInMinutes,
        'requestedLanguage': requestedLanguage,
        'requiresCar': requiresCar,
        'travelersCount': travelersCount,
      };
}
