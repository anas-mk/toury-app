import 'package:equatable/equatable.dart';
import '../../domain/entities/rating_entity.dart';

abstract class UserRatingsState extends Equatable {
  const UserRatingsState();

  @override
  List<Object?> get props => [];
}

class UserRatingsInitial extends UserRatingsState {}

class UserRatingsLoading extends UserRatingsState {}

class UserRatingsSubmitting extends UserRatingsState {}

class UserRatingsSubmitted extends UserRatingsState {}

class UserRatingsLoaded extends UserRatingsState {
  final List<RatingEntity> ratings;
  final bool hasMore;

  const UserRatingsLoaded({required this.ratings, this.hasMore = false});

  @override
  List<Object?> get props => [ratings, hasMore];
}

class RatingSummaryLoaded extends UserRatingsState {
  final RatingSummaryEntity summary;

  const RatingSummaryLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class BookingRatingStateLoaded extends UserRatingsState {
  final bool canRate;
  final RatingEntity? existingRating;

  const BookingRatingStateLoaded({required this.canRate, this.existingRating});

  @override
  List<Object?> get props => [canRate, existingRating];
}

class UserRatingsError extends UserRatingsState {
  final String message;

  const UserRatingsError(this.message);

  @override
  List<Object?> get props => [message];
}
