import 'package:equatable/equatable.dart';

class HelperLanguage extends Equatable {
  /// ISO 639-1 language code, e.g. `en`, `ar`, `fr`.
  final String languageCode;

  /// Human-friendly name as it should be shown in the UI, e.g. `English`.
  final String languageName;

  /// Free-form skill level returned by the backend (e.g. `Native`, `Fluent`).
  final String? level;
  final bool isVerified;

  const HelperLanguage({
    required this.languageCode,
    required this.languageName,
    this.level,
    required this.isVerified,
  });

  @override
  List<Object?> get props => [languageCode, languageName, level, isVerified];
}

class HelperServiceArea extends Equatable {
  /// ISO 3166-1 alpha-2 country code (e.g. `EG`).
  final String country;
  final String city;
  final String? areaName;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final bool isPrimary;

  const HelperServiceArea({
    required this.country,
    required this.city,
    this.areaName,
    this.latitude,
    this.longitude,
    this.radiusKm,
    required this.isPrimary,
  });

  @override
  List<Object?> get props =>
      [country, city, areaName, latitude, longitude, radiusKm, isPrimary];
}

class HelperCarInfo extends Equatable {
  final String? brand;
  final String? model;
  final String? color;
  final String? type;

  const HelperCarInfo({this.brand, this.model, this.color, this.type});

  @override
  List<Object?> get props => [brand, model, color, type];
}

/// Response of `GET /user/bookings/helpers/{helperId}/profile`.
class HelperBookingProfile extends Equatable {
  final String helperId;
  final String fullName;
  final String? profileImageUrl;
  final String? gender;
  final int? age;
  final String? bio;
  final double rating;
  final int ratingCount;
  final int completedTrips;
  final int experienceYears;
  final double hourlyRate;
  final List<HelperLanguage> languages;
  final List<HelperServiceArea> serviceAreas;
  final List<String> certificates;
  final bool hasCar;
  final HelperCarInfo? car;
  final String availabilityState;
  final bool canAcceptInstant;
  final bool canAcceptScheduled;
  final int? averageResponseTimeSeconds;
  final double? acceptanceRate;

  const HelperBookingProfile({
    required this.helperId,
    required this.fullName,
    this.profileImageUrl,
    this.gender,
    this.age,
    this.bio,
    required this.rating,
    required this.ratingCount,
    required this.completedTrips,
    required this.experienceYears,
    required this.hourlyRate,
    required this.languages,
    required this.serviceAreas,
    required this.certificates,
    required this.hasCar,
    this.car,
    required this.availabilityState,
    required this.canAcceptInstant,
    required this.canAcceptScheduled,
    this.averageResponseTimeSeconds,
    this.acceptanceRate,
  });

  @override
  List<Object?> get props => [
        helperId,
        fullName,
        profileImageUrl,
        gender,
        age,
        bio,
        rating,
        ratingCount,
        completedTrips,
        experienceYears,
        hourlyRate,
        languages,
        serviceAreas,
        certificates,
        hasCar,
        car,
        availabilityState,
        canAcceptInstant,
        canAcceptScheduled,
        averageResponseTimeSeconds,
        acceptanceRate,
      ];
}
