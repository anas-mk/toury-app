import 'package:equatable/equatable.dart';

class HelperBookingEntity extends Equatable {
  final String id;
  final String name;
  final String? profileImageUrl;
  final double rating;
  final int completedTrips;
  final String? bio;
  final List<String> languages; // For search list
  final List<LanguageEntity>? detailedLanguages; // For profile
  final List<String>? certificates;
  final CarEntity? car;
  final double? hourlyRate;
  final double? estimatedPrice;
  final double acceptanceRate;
  final int age;
  final String gender;
  final int experienceYears;
  final List<ServiceAreaEntity> serviceAreas;
  final double? latitude;
  final double? longitude;
  final String? availabilityStatus;
  final bool canAcceptInstant;
  final bool canAcceptScheduled;
  final List<String>? suitabilityReasons;
  final int? matchScore;
  final double? distanceKm;
  final double? estimatedDistanceKm;

  const HelperBookingEntity({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.rating,
    required this.completedTrips,
    this.bio,
    required this.languages,
    this.detailedLanguages,
    this.certificates,
    this.car,
    this.hourlyRate,
    this.estimatedPrice,
    required this.acceptanceRate,
    required this.age,
    required this.gender,
    required this.experienceYears,
    required this.serviceAreas,
    this.latitude,
    this.longitude,
    this.availabilityStatus,
    this.canAcceptInstant = false,
    this.canAcceptScheduled = false,
    this.suitabilityReasons,
    this.matchScore,
    this.distanceKm,
    this.estimatedDistanceKm,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        profileImageUrl,
        rating,
        completedTrips,
        bio,
        languages,
        detailedLanguages,
        certificates,
        car,
        hourlyRate,
        estimatedPrice,
        acceptanceRate,
        age,
        gender,
        experienceYears,
        serviceAreas,
        latitude,
        longitude,
        availabilityStatus,
        canAcceptInstant,
        canAcceptScheduled,
        suitabilityReasons,
        matchScore,
        distanceKm,
        estimatedDistanceKm,
      ];
}

class LanguageEntity extends Equatable {
  final String code;
  final String name;
  final String level;
  final bool isVerified;

  const LanguageEntity({
    required this.code,
    required this.name,
    required this.level,
    required this.isVerified,
  });

  @override
  List<Object?> get props => [code, name, level, isVerified];
}

class ServiceAreaEntity extends Equatable {
  final String city;
  final String? areaName;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final bool isPrimary;

  const ServiceAreaEntity({
    required this.city,
    this.areaName,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.isPrimary,
  });

  @override
  List<Object?> get props => [city, areaName, latitude, longitude, radiusKm, isPrimary];
}

class CarEntity extends Equatable {
  final String brand;
  final String model;
  final String color;
  final String? type;
  final String? plateNumber;
  final int? year;

  const CarEntity({
    required this.brand,
    required this.model,
    required this.color,
    this.type,
    this.plateNumber,
    this.year,
  });

  @override
  List<Object?> get props => [brand, model, color, type, plateNumber, year];
}
