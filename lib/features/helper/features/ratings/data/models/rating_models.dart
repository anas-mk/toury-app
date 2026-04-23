import '../../domain/entities/rating_entities.dart';

class RatingModel extends RatingEntity {
  const RatingModel({
    required super.id,
    required super.reviewerName,
    super.reviewerImage,
    required super.stars,
    super.comment,
    required super.tags,
    required super.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id']?.toString() ?? '',
      reviewerName: json['reviewerName'] ?? 'Unknown',
      reviewerImage: json['reviewerImage'],
      stars: (json['stars'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class RatingSummaryModel extends RatingSummaryEntity {
  const RatingSummaryModel({
    required super.averageStars,
    required super.totalCount,
    required super.distribution,
  });

  factory RatingSummaryModel.fromJson(Map<String, dynamic> json) {
    final dist = Map<String, dynamic>.from(json['distribution'] ?? {});
    final distribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      distribution[i] = (dist[i.toString()] as num?)?.toInt() ?? 0;
    }

    return RatingSummaryModel(
      averageStars: (json['averageStars'] as num?)?.toDouble() ?? 0.0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      distribution: distribution,
    );
  }
}

class RatingStatusModel extends RatingStatusEntity {
  const RatingStatusModel({
    super.userToHelper,
    super.helperToUser,
    required super.callerHasRated,
    required super.canRate,
  });

  factory RatingStatusModel.fromJson(Map<String, dynamic> json) {
    return RatingStatusModel(
      userToHelper: json['userToHelper'] != null ? RatingModel.fromJson(json['userToHelper']) : null,
      helperToUser: json['helperToUser'] != null ? RatingModel.fromJson(json['helperToUser']) : null,
      callerHasRated: json['callerHasRated'] ?? false,
      canRate: json['canRate'] ?? false,
    );
  }
}
