import 'package:equatable/equatable.dart';
import '../../domain/entities/rating_entity.dart';

abstract class UserRatingsState extends Equatable {
  const UserRatingsState();

  @override
  List<Object?> get props => [];
}

class UserRatingsInitial extends UserRatingsState {}

class RatingLoading extends UserRatingsState {}

class RatingLoaded extends UserRatingsState {
  final List<RatingEntity> ratings;
  final RatingSummaryEntity? summary;

  const RatingLoaded({required this.ratings, this.summary});

  @override
  List<Object?> get props => [ratings, summary];
}

class RatingSuccess extends UserRatingsState {}

class RatingError extends UserRatingsState {
  final String message;

  const RatingError(this.message);

  @override
  List<Object?> get props => [message];
}
