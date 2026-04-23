import '../../domain/entities/helper_entity.dart';

class HelperModel extends HelperEntity {
  const HelperModel({
    required super.id,
    required super.name,
    required super.rating,
    required super.reviewsCount,
    super.profileImageUrl,
    required super.languages,
    required super.pricePerHour,
  });

  factory HelperModel.fromJson(Map<String, dynamic> json) {
    return HelperModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      profileImageUrl: json['profileImageUrl']?.toString(),
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'profileImageUrl': profileImageUrl,
      'languages': languages,
      'pricePerHour': pricePerHour,
    };
  }
}
