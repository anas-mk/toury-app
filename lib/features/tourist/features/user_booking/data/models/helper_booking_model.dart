import '../../domain/entities/helper_booking_entity.dart';

class HelperBookingModel extends HelperBookingEntity {
  static const String defaultProfileImage = 'https://i.pinimg.com/736x/e8/7a/b0/e87ab0a15b2b65662020e614f7e05ef1.jpg';
  static const String baseUrl = 'https://tourestaapi.runasp.net';

  const HelperBookingModel({
    required super.id,
    required super.name,
    super.profileImageUrl,
    required super.rating,
    required super.completedTrips,
    super.bio,
    required super.languages,
    super.detailedLanguages,
    super.certificates,
    super.car,
    super.hourlyRate,
    super.estimatedPrice,
    required super.acceptanceRate,
    required super.age,
    required super.gender,
    required super.experienceYears,
    required super.serviceAreas,
    super.latitude,
    super.longitude,
    super.availabilityStatus,
    super.canAcceptInstant = false,
    super.canAcceptScheduled = false,
    super.suitabilityReasons,
    super.matchScore,
    super.distanceKm,
  });

  factory HelperBookingModel.fromJson(Map<String, dynamic> json) {
    String? profileImageUrl = json['profileImageUrl'];
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      if (profileImageUrl.startsWith('/')) {
        profileImageUrl = '$baseUrl$profileImageUrl';
      }
    } else {
      profileImageUrl = defaultProfileImage;
    }

    final String extractedId = json['helperId']?.toString() ?? json['id']?.toString() ?? '';
    
    return HelperBookingModel(
      id: extractedId,
      name: json['fullName'] ?? json['name'] ?? 'Unknown',
      profileImageUrl: profileImageUrl,
      rating: (json['rating'] ?? 0.0).toDouble(),
      completedTrips: json['completedTrips'] ?? json['tripsCount'] ?? 0,
      bio: json['bio'],
      languages: List<String>.from(json['languages']?.map((l) => l is String ? l : (l['languageName'] ?? '')) ?? []),
      detailedLanguages: json['languages'] != null && json['languages'] is List && json['languages'].isNotEmpty && json['languages'][0] is Map
          ? (json['languages'] as List).map((e) => LanguageModel.fromJson(e)).toList()
          : null,
      certificates: json['certificates'] != null ? List<String>.from(json['certificates']) : null,
      car: json['car'] != null ? CarModel.fromJson(json['car']) : (json['hasCar'] == true ? CarModel.fromDescription(json['carDescription']) : null),
      hourlyRate: json['hourlyRate'] != null ? (json['hourlyRate'] as num).toDouble() : null,
      estimatedPrice: json['estimatedPrice'] != null ? (json['estimatedPrice'] as num).toDouble() : null,
      acceptanceRate: (json['acceptanceRate'] ?? 0.0).toDouble(),
      age: json['age'] ?? 0,
      gender: json['gender'] ?? 'Unknown',
      experienceYears: json['experienceYears'] ?? 0,
      serviceAreas: (json['serviceAreas'] as List? ?? []).map((e) => ServiceAreaModel.fromJson(e)).toList(),
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      availabilityStatus: json['availabilityStatus'] ?? json['availabilityState'],
      canAcceptInstant: json['canAcceptInstant'] ?? false,
      canAcceptScheduled: json['canAcceptScheduled'] ?? false,
      suitabilityReasons: json['suitabilityReasons'] != null ? List<String>.from(json['suitabilityReasons']) : null,
      matchScore: json['matchScore'],
      distanceKm: json['distanceKm'] != null ? (json['distanceKm'] as num).toDouble() : null,
    );
  }
}

class LanguageModel extends LanguageEntity {
  const LanguageModel({
    required super.code,
    required super.name,
    required super.level,
    required super.isVerified,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      code: json['languageCode'] ?? '',
      name: json['languageName'] ?? '',
      level: json['level'] ?? '',
      isVerified: json['isVerified'] ?? false,
    );
  }
}

class ServiceAreaModel extends ServiceAreaEntity {
  const ServiceAreaModel({
    required super.city,
    super.areaName,
    required super.latitude,
    required super.longitude,
    required super.radiusKm,
    required super.isPrimary,
  });

  factory ServiceAreaModel.fromJson(dynamic json) {
    if (json is String) {
      return ServiceAreaModel(city: json, latitude: 0, longitude: 0, radiusKm: 0, isPrimary: false);
    }
    final map = json as Map<String, dynamic>;
    return ServiceAreaModel(
      city: map['city'] ?? map['cityName'] ?? '',
      areaName: map['areaName'],
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      radiusKm: (map['radiusKm'] ?? 0.0).toDouble(),
      isPrimary: map['isPrimary'] ?? false,
    );
  }
}

class CarModel extends CarEntity {
  const CarModel({
    required super.brand,
    required super.model,
    required super.color,
    super.type,
    super.plateNumber,
    super.year,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      color: json['color'] ?? '',
      type: json['type'],
      plateNumber: json['plateNumber'],
      year: json['year'],
    );
  }

  factory CarModel.fromDescription(String? description) {
    return CarModel(
      brand: description?.split(' ').first ?? 'Car',
      model: description?.split(' ').skip(1).join(' ') ?? '',
      color: '',
    );
  }
}
