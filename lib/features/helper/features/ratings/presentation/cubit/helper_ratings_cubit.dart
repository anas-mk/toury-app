import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rating_entities.dart';
import '../../domain/usecases/rating_usecases.dart';

abstract class HelperRatingsState extends Equatable {
  const HelperRatingsState();
  @override
  List<Object?> get props => [];
}

class RatingsInitial extends HelperRatingsState {}
class RatingsLoading extends HelperRatingsState {}

class RatingsLoaded extends HelperRatingsState {
  final RatingSummaryEntity? summary;
  final List<RatingEntity> receivedRatings;
  final Map<String, RatingStatusEntity> bookingStatuses;
  final bool isSubmitting;

  const RatingsLoaded({
    this.summary,
    this.receivedRatings = const [],
    this.bookingStatuses = const {},
    this.isSubmitting = false,
  });

  RatingsLoaded copyWith({
    RatingSummaryEntity? summary,
    List<RatingEntity>? receivedRatings,
    Map<String, RatingStatusEntity>? bookingStatuses,
    bool? isSubmitting,
  }) {
    return RatingsLoaded(
      summary: summary ?? this.summary,
      receivedRatings: receivedRatings ?? this.receivedRatings,
      bookingStatuses: bookingStatuses ?? this.bookingStatuses,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [summary, receivedRatings, bookingStatuses, isSubmitting];
}

class RatingsError extends HelperRatingsState {
  final String message;
  const RatingsError(this.message);
  @override
  List<Object?> get props => [message];
}

class HelperRatingsCubit extends Cubit<HelperRatingsState> {
  final SubmitUserRatingUseCase submitRatingUseCase;
  final GetBookingRatingStatusUseCase getStatusUseCase;
  final GetReceivedRatingsUseCase getReceivedUseCase;
  final GetRatingsSummaryUseCase getSummaryUseCase;

  HelperRatingsCubit({
    required this.submitRatingUseCase,
    required this.getStatusUseCase,
    required this.getReceivedUseCase,
    required this.getSummaryUseCase,
  }) : super(RatingsInitial());

  Future<void> loadSummaryAndRatings() async {
    emit(RatingsLoading());
    final summaryResult = await getSummaryUseCase();
    final receivedResult = await getReceivedUseCase();

    summaryResult.fold(
      (failure) => emit(RatingsError(failure.message)),
      (summary) {
        receivedResult.fold(
          (failure) => emit(RatingsError(failure.message)),
          (ratings) => emit(RatingsLoaded(summary: summary, receivedRatings: ratings)),
        );
      },
    );
  }

  Future<void> fetchBookingStatus(String bookingId) async {
    final currentState = state is RatingsLoaded ? (state as RatingsLoaded) : const RatingsLoaded();
    
    final result = await getStatusUseCase(bookingId);
    result.fold(
      (failure) => null,
      (status) {
        final newStatuses = Map<String, RatingStatusEntity>.from(currentState.bookingStatuses);
        newStatuses[bookingId] = status;
        emit(currentState.copyWith(bookingStatuses: newStatuses));
      },
    );
  }

  Future<void> submitRating(String bookingId, int stars, String? comment, List<String> tags) async {
    final currentState = state is RatingsLoaded ? (state as RatingsLoaded) : const RatingsLoaded();
    emit(currentState.copyWith(isSubmitting: true));

    final result = await submitRatingUseCase(bookingId, stars: stars, comment: comment, tags: tags);
    
    result.fold(
      (failure) => emit(RatingsError(failure.message)),
      (_) {
        fetchBookingStatus(bookingId); // Refresh status after rating
        emit(currentState.copyWith(isSubmitting: false));
      },
    );
  }
}
