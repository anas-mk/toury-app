import 'package:equatable/equatable.dart';

class RatingEntity extends Equatable {
  final String id;
  final String bookingId;
  final String authorId;
  final String authorType;
  final String targetId;
  final String targetType;
  final int stars;
  final String comment;
  final List<String> tags;
  final DateTime createdAt;

  const RatingEntity({
    required this.id,
    required this.bookingId,
    required this.authorId,
    required this.authorType,
    required this.targetId,
    required this.targetType,
    required this.stars,
    required this.comment,
    required this.tags,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        bookingId,
        authorId,
        authorType,
        targetId,
        targetType,
        stars,
        comment,
        tags,
        createdAt,
      ];
}

class RatingSummaryEntity extends Equatable {
  final String targetId;
  final String targetType;
  final int totalCount;
  final double averageStars;
  final Map<int, int> distribution;

  const RatingSummaryEntity({
    required this.targetId,
    required this.targetType,
    required this.totalCount,
    required this.averageStars,
    required this.distribution,
  });

  @override
  List<Object?> get props => [
        targetId,
        targetType,
        totalCount,
        averageStars,
        distribution,
      ];
}
