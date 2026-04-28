import '../../domain/entities/helper_booking_profile.dart';
import 'json_helpers.dart';

class HelperLanguageModel extends HelperLanguage {
  const HelperLanguageModel({
    required super.languageCode,
    required super.languageName,
    super.level,
    required super.isVerified,
  });

  factory HelperLanguageModel.fromJson(Map<String, dynamic> json) {
    return HelperLanguageModel(
      languageCode: json['languageCode']?.toString() ?? '',
      languageName: json['languageName']?.toString() ?? '',
      level: json['level']?.toString(),
      isVerified: parseBool(json['isVerified']),
    );
  }
}

class HelperServiceAreaModel extends HelperServiceArea {
  const HelperServiceAreaModel({
    required super.country,
    required super.city,
    super.areaName,
    super.latitude,
    super.longitude,
    super.radiusKm,
    required super.isPrimary,
  });

  factory HelperServiceAreaModel.fromJson(Map<String, dynamic> json) {
    return HelperServiceAreaModel(
      country: json['country']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      areaName: json['areaName']?.toString(),
      latitude: parseDoubleOrNull(json['latitude']),
      longitude: parseDoubleOrNull(json['longitude']),
      radiusKm: parseDoubleOrNull(json['radiusKm']),
      isPrimary: parseBool(json['isPrimary']),
    );
  }
}

class HelperCarInfoModel extends HelperCarInfo {
  const HelperCarInfoModel({
    super.brand,
    super.model,
    super.color,
    super.type,
  });

  factory HelperCarInfoModel.fromJson(Map<String, dynamic> json) {
    return HelperCarInfoModel(
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      color: json['color']?.toString(),
      type: json['type']?.toString(),
    );
  }
}

class HelperBookingProfileModel extends HelperBookingProfile {
  const HelperBookingProfileModel({
    required super.helperId,
    required super.fullName,
    super.profileImageUrl,
    super.gender,
    super.age,
    super.bio,
    required super.rating,
    required super.ratingCount,
    required super.completedTrips,
    required super.experienceYears,
    required super.hourlyRate,
    required super.languages,
    required super.serviceAreas,
    required super.certificates,
    required super.hasCar,
    super.car,
    required super.availabilityState,
    required super.canAcceptInstant,
    required super.canAcceptScheduled,
    super.averageResponseTimeSeconds,
    super.acceptanceRate,
  });

  factory HelperBookingProfileModel.fromJson(Map<String, dynamic> json) {
    final car = json['car'];
    return HelperBookingProfileModel(
      helperId: json['helperId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      profileImageUrl: json['profileImageUrl']?.toString(),
      gender: json['gender']?.toString(),
      age: parseIntOrNull(json['age']),
      bio: json['bio']?.toString(),
      rating: parseDouble(json['rating']),
      ratingCount: parseInt(json['ratingCount']),
      completedTrips: parseInt(json['completedTrips']),
      experienceYears: parseInt(json['experienceYears']),
      hourlyRate: parseDouble(json['hourlyRate']),
      languages: (json['languages'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(HelperLanguageModel.fromJson)
              .toList() ??
          const [],
      serviceAreas: (json['serviceAreas'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(HelperServiceAreaModel.fromJson)
              .toList() ??
          const [],
      certificates: parseStringList(json['certificates']),
      hasCar: parseBool(json['hasCar']),
      car: car is Map<String, dynamic> ? HelperCarInfoModel.fromJson(car) : null,
      availabilityState: json['availabilityState']?.toString() ?? 'Unknown',
      canAcceptInstant: parseBool(json['canAcceptInstant']),
      canAcceptScheduled: parseBool(json['canAcceptScheduled']),
      averageResponseTimeSeconds:
          parseIntOrNull(json['averageResponseTimeSeconds']),
      acceptanceRate: parseDoubleOrNull(json['acceptanceRate']),
    );
  }
}
