import '../../domain/entities/alternative_helper_entity.dart';

class AlternativeHelperModel extends AlternativeHelperEntity {
  const AlternativeHelperModel({
    required super.id,
    required super.name,
    required super.rating,
    required super.distance,
    required super.pricePerHour,
  });

  factory AlternativeHelperModel.fromJson(Map<String, dynamic> json) {
    return AlternativeHelperModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'distance': distance,
      'pricePerHour': pricePerHour,
    };
  }
}
