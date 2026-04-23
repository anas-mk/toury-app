import 'package:equatable/equatable.dart';

class RatingEntity extends Equatable {
  final String id;
  final String reviewerName;
  final String? reviewerImage;
  final double stars;
  final String? comment;
  final List<String> tags;
  final DateTime createdAt;

  const RatingEntity({
    required this.id,
    required this.reviewerName,
    this.reviewerImage,
    required this.stars,
    this.comment,
    required this.tags,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, reviewerName, reviewerImage, stars, comment, tags, createdAt];
}

class RatingSummaryEntity extends Equatable {
  final double averageStars;
  final int totalCount;
  final Map<int, int> distribution;

  const RatingSummaryEntity({
    required this.averageStars,
    required this.totalCount,
    required this.distribution,
  });

  @override
  List<Object?> get props => [averageStars, totalCount, distribution];
}

class RatingStatusEntity extends Equatable {
  final RatingEntity? userToHelper;
  final RatingEntity? helperToUser;
  final bool callerHasRated;
  final bool canRate;

  const RatingStatusEntity({
    this.userToHelper,
    this.helperToUser,
    required this.callerHasRated,
    required this.canRate,
  });

  @override
  List<Object?> get props => [userToHelper, helperToUser, callerHasRated, canRate];
}
