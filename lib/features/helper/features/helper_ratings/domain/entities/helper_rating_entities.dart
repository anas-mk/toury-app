import 'package:equatable/equatable.dart';

class RatingEntity extends Equatable {
  final String id;
  final String bookingId;
  final String authorId;
  final String authorType;
  final String authorDisplayName;
  final String authorAvatarUrl;
  final String targetId;
  final String targetType;
  final String direction;
  final double stars;
  final String comment;
  final List<String> tags;
  final String bookingType;
  final DateTime createdAt;

  const RatingEntity({
    required this.id,
    required this.bookingId,
    required this.authorId,
    required this.authorType,
    required this.authorDisplayName,
    required this.authorAvatarUrl,
    required this.targetId,
    required this.targetType,
    required this.direction,
    required this.stars,
    required this.comment,
    required this.tags,
    required this.bookingType,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        bookingId,
        authorId,
        authorType,
        authorDisplayName,
        authorAvatarUrl,
        targetId,
        targetType,
        direction,
        stars,
        comment,
        tags,
        bookingType,
        createdAt,
      ];
}

class RatingStateEntity extends Equatable {
  final String bookingId;
  final bool userToHelper;
  final bool helperToUser;
  final bool callerHasRated;
  final bool canRate;

  const RatingStateEntity({
    required this.bookingId,
    required this.userToHelper,
    required this.helperToUser,
    required this.callerHasRated,
    required this.canRate,
  });

  @override
  List<Object?> get props => [
        bookingId,
        userToHelper,
        helperToUser,
        callerHasRated,
        canRate,
      ];
}

class RatingsSummaryEntity extends Equatable {
  final int totalCount;
  final double averageStars;
  final Map<int, int> distribution;

  const RatingsSummaryEntity({
    required this.totalCount,
    required this.averageStars,
    required this.distribution,
  });

  @override
  List<Object?> get props => [totalCount, averageStars, distribution];
}
