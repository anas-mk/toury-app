import '../../domain/entities/helper_rating_entities.dart';

class RatingModel extends RatingEntity {
  const RatingModel({
    required super.id,
    required super.bookingId,
    required super.authorId,
    required super.authorType,
    required super.authorDisplayName,
    required super.authorAvatarUrl,
    required super.targetId,
    required super.targetType,
    required super.direction,
    required super.stars,
    required super.comment,
    required super.tags,
    required super.bookingType,
    required super.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      authorId: json['authorId'] ?? '',
      authorType: json['authorType'] ?? '',
      authorDisplayName: json['authorDisplayName'] ?? 'User',
      authorAvatarUrl: json['authorAvatarUrl'] ?? '',
      targetId: json['targetId'] ?? '',
      targetType: json['targetType'] ?? '',
      direction: json['direction'] ?? '',
      stars: (json['stars'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      bookingType: json['bookingType'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'authorId': authorId,
      'authorType': authorType,
      'authorDisplayName': authorDisplayName,
      'authorAvatarUrl': authorAvatarUrl,
      'targetId': targetId,
      'targetType': targetType,
      'direction': direction,
      'stars': stars,
      'comment': comment,
      'tags': tags,
      'bookingType': bookingType,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class RatingStateModel extends RatingStateEntity {
  const RatingStateModel({
    required super.bookingId,
    super.userToHelper,
    super.helperToUser,
    required super.callerHasRated,
    required super.canRate,
  });

  factory RatingStateModel.fromJson(Map<String, dynamic> json) {
    return RatingStateModel(
      bookingId: json['bookingId'] ?? '',
      userToHelper: json['userToHelper'] != null
          ? RatingModel.fromJson(json['userToHelper'] as Map<String, dynamic>)
          : null,
      helperToUser: json['helperToUser'] != null
          ? RatingModel.fromJson(json['helperToUser'] as Map<String, dynamic>)
          : null,
      callerHasRated: json['callerHasRated'] ?? false,
      canRate: json['canRate'] ?? false,
    );
  }
}

class RatingsSummaryModel extends RatingsSummaryEntity {
  const RatingsSummaryModel({
    required super.totalCount,
    required super.averageStars,
    required super.distribution,
  });

  factory RatingsSummaryModel.fromJson(Map<String, dynamic> json) {
    final distMap = json['distribution'] as Map<String, dynamic>? ?? {};
    final distribution = <int, int>{};
    distMap.forEach((key, value) {
      distribution[int.parse(key)] = value as int;
    });

    return RatingsSummaryModel(
      totalCount: json['totalCount'] ?? 0,
      averageStars: (json['averageStars'] ?? 0).toDouble(),
      distribution: distribution,
    );
  }
}
