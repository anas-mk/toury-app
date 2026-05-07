import 'package:equatable/equatable.dart';

import 'price_breakdown.dart';

/// One element of the response from `POST /user/bookings/instant/search`.
class HelperSearchResult extends Equatable {
  final String helperId;
  final String fullName;
  final String? profileImageUrl;
  final double rating;
  final int completedTrips;
  final int experienceYears;

  /// ISO 639-1 language codes (e.g. `["en", "ar"]`).
  final List<String> languages;
  final bool hasCar;
  final String? carDescription;
  final double? hourlyRate;
  final double estimatedPrice;
  final PriceBreakdown? priceBreakdown;

  /// Raw availability state string from the backend (e.g. `AvailableNow`).
  final String availabilityStatus;
  final bool canAcceptInstant;
  final bool canAcceptScheduled;

  /// Average response time in seconds (`null` if unknown).
  final int? averageResponseTimeSeconds;

  /// `0.0`..`1.0` — the fraction of requests this helper accepted recently.
  final double? acceptanceRate;
  final List<String> suitabilityReasons;

  /// `0`..`100` — backend-computed match score.
  final int matchScore;
  final double? distanceKm;

  const HelperSearchResult({
    required this.helperId,
    required this.fullName,
    this.profileImageUrl,
    required this.rating,
    required this.completedTrips,
    required this.experienceYears,
    required this.languages,
    required this.hasCar,
    this.carDescription,
    this.hourlyRate,
    required this.estimatedPrice,
    this.priceBreakdown,
    required this.availabilityStatus,
    required this.canAcceptInstant,
    required this.canAcceptScheduled,
    this.averageResponseTimeSeconds,
    this.acceptanceRate,
    required this.suitabilityReasons,
    required this.matchScore,
    this.distanceKm,
  });

  @override
  List<Object?> get props => [
        helperId,
        fullName,
        profileImageUrl,
        rating,
        completedTrips,
        experienceYears,
        languages,
        hasCar,
        carDescription,
        hourlyRate,
        estimatedPrice,
        priceBreakdown,
        availabilityStatus,
        canAcceptInstant,
        canAcceptScheduled,
        averageResponseTimeSeconds,
        acceptanceRate,
        suitabilityReasons,
        matchScore,
        distanceKm,
      ];
}
