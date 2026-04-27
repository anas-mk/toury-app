import '../../domain/entities/helper_search_result.dart';
import 'json_helpers.dart';
import 'price_breakdown_model.dart';

class HelperSearchResultModel extends HelperSearchResult {
  const HelperSearchResultModel({
    required super.helperId,
    required super.fullName,
    super.profileImageUrl,
    required super.rating,
    required super.completedTrips,
    required super.experienceYears,
    required super.languages,
    required super.hasCar,
    super.carDescription,
    required super.hourlyRate,
    required super.estimatedPrice,
    super.priceBreakdown,
    required super.availabilityStatus,
    required super.canAcceptInstant,
    required super.canAcceptScheduled,
    super.averageResponseTimeSeconds,
    super.acceptanceRate,
    required super.suitabilityReasons,
    required super.matchScore,
    super.distanceKm,
  });

  factory HelperSearchResultModel.fromJson(Map<String, dynamic> json) {
    final breakdown = json['priceBreakdown'];
    return HelperSearchResultModel(
      helperId: json['helperId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      profileImageUrl: json['profileImageUrl']?.toString(),
      rating: parseDouble(json['rating']),
      completedTrips: parseInt(json['completedTrips']),
      experienceYears: parseInt(json['experienceYears']),
      languages: parseStringList(json['languages']),
      hasCar: parseBool(json['hasCar']),
      carDescription: json['carDescription']?.toString(),
      hourlyRate: parseDouble(json['hourlyRate']),
      estimatedPrice: parseDouble(json['estimatedPrice']),
      priceBreakdown: breakdown is Map<String, dynamic>
          ? PriceBreakdownModel.fromJson(breakdown)
          : null,
      availabilityStatus:
          json['availabilityStatus']?.toString() ?? 'Unknown',
      canAcceptInstant: parseBool(json['canAcceptInstant']),
      canAcceptScheduled: parseBool(json['canAcceptScheduled']),
      averageResponseTimeSeconds:
          parseIntOrNull(json['averageResponseTimeSeconds']),
      acceptanceRate: parseDoubleOrNull(json['acceptanceRate']),
      suitabilityReasons: parseStringList(json['suitabilityReasons']),
      matchScore: parseInt(json['matchScore']),
      distanceKm: parseDoubleOrNull(json['distanceKm']),
    );
  }
}
