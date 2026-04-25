import '../../domain/entities/rating_entity.dart';

class RatingModel extends RatingEntity {
  const RatingModel({
    required super.id,
    required super.bookingId,
    required super.authorId,
    required super.authorType,
    required super.targetId,
    required super.targetType,
    required super.stars,
    required super.comment,
    required super.tags,
    required super.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorType: json['authorType'] ?? '',
      targetId: json['targetId']?.toString() ?? '',
      targetType: json['targetType'] ?? '',
      stars: (json['stars'] ?? 0).toInt(),
      comment: json['comment'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'authorId': authorId,
      'authorType': authorType,
      'targetId': targetId,
      'targetType': targetType,
      'stars': stars,
      'comment': comment,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class RatingSummaryModel extends RatingSummaryEntity {
  const RatingSummaryModel({
    required super.targetId,
    required super.targetType,
    required super.totalCount,
    required super.averageStars,
    required super.distribution,
  });

  factory RatingSummaryModel.fromJson(Map<String, dynamic> json) {
    final distJson = json['distribution'] as Map<String, dynamic>? ?? {};
    final distribution = distJson.map((key, value) => MapEntry(int.parse(key), (value as num).toInt()));
    
    return RatingSummaryModel(
      targetId: json['targetId']?.toString() ?? '',
      targetType: json['targetType'] ?? '',
      totalCount: (json['totalCount'] ?? 0).toInt(),
      averageStars: (json['averageStars'] ?? 0.0).toDouble(),
      distribution: distribution,
    );
  }
}
