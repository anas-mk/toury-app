import '../../domain/entities/helper_booking_entity.dart';

class HelperBookingModel extends HelperBookingEntity {
  static const String defaultProfileImage =
      'https://i.pinimg.com/736x/e8/7a/b0/e87ab0a15b2b65662020e614f7e05ef1.jpg';
  static const String baseUrl = 'https://tourestaapi.runasp.net';

  const HelperBookingModel({
    required super.id,
    required super.name,
    super.profileImageUrl,
    required super.rating,
    required super.tripsCount,
    super.bio,
    required super.languages,
    super.certificates,
    super.car,
    required super.responseSpeed,
    required super.acceptanceRate,
    required super.age,
    required super.gender,
    required super.experience,
    required super.serviceAreas,
    super.latitude,
    super.longitude,
    super.isAvailable,
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

    final String extractedId = json['id']?.toString() ?? json['helperId']?.toString() ?? '';
    
    return HelperBookingModel(
      id: extractedId,
      name: json['name'] ?? json['fullName'] ?? 'Unknown',
      profileImageUrl: profileImageUrl,
      rating: (json['rating'] ?? 0.0).toDouble(),
      tripsCount: json['tripsCount'] ?? 0,
      bio: json['bio'],
      languages: List<String>.from(json['languages'] ?? []),
      certificates: List<String>.from(json['certificates'] ?? []),
      car: json['car'] != null ? CarModel.fromJson(json['car']) : null,
      responseSpeed: json['responseSpeed'] ?? 'Normal',
      acceptanceRate: (json['acceptanceRate'] ?? 0.0).toDouble(),
      age: json['age'] ?? 0,
      gender: json['gender'] ?? 'Unknown',
      experience: json['experience'] ?? 'None',
      serviceAreas: List<String>.from(json['serviceAreas'] ?? []),
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : (30.0444 + (extractedId.hashCode % 100) / 1000.0),
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : (31.2357 + (extractedId.hashCode % 100) / 1000.0),
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'profileImageUrl': profileImageUrl,
        'rating': rating,
        'tripsCount': tripsCount,
        'bio': bio,
        'languages': languages,
        'certificates': certificates,
        'car': car != null ? (car as CarModel).toJson() : null,
        'responseSpeed': responseSpeed,
        'acceptanceRate': acceptanceRate,
        'age': age,
        'gender': gender,
        'experience': experience,
        'serviceAreas': serviceAreas,
        'latitude': latitude,
        'longitude': longitude,
        'isAvailable': isAvailable,
      };
}

class CarModel extends CarEntity {
  const CarModel({
    required super.model,
    required super.color,
    required super.plateNumber,
    required super.year,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      model: json['model'] ?? '',
      color: json['color'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      year: json['year'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'model': model,
        'color': color,
        'plateNumber': plateNumber,
        'year': year,
      };
}
