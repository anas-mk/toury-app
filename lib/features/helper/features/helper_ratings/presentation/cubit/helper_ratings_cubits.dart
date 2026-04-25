import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_rating_entities.dart';
import '../../domain/usecases/helper_rating_usecases.dart';

// ── HelperRatingsCubit ────────────────────────────────────────────────────────

abstract class HelperRatingsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HelperRatingsInitial extends HelperRatingsState {}

class HelperRatingsLoading extends HelperRatingsState {}

class HelperRatingsLoaded extends HelperRatingsState {
  final List<RatingEntity> reviews;
  final RatingsSummaryEntity summary;
  final bool hasReachedMax;

  HelperRatingsLoaded({
    required this.reviews,
    required this.summary,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [reviews, summary, hasReachedMax];
}

class HelperRatingsError extends HelperRatingsState {
  final String message;
  HelperRatingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class HelperRatingsCubit extends Cubit<HelperRatingsState> {
  final GetReceivedRatingsUseCase getReceivedRatingsUseCase;
  final GetRatingsSummaryUseCase getRatingsSummaryUseCase;

  int _currentPage = 1;
  static const int _pageSize = 20;

  HelperRatingsCubit({
    required this.getReceivedRatingsUseCase,
    required this.getRatingsSummaryUseCase,
  }) : super(HelperRatingsInitial());

  Future<void> load() async {
    emit(HelperRatingsLoading());
    _currentPage = 1;

    final summaryRes = await getRatingsSummaryUseCase();
    final reviewsRes = await getReceivedRatingsUseCase(page: _currentPage, pageSize: _pageSize);

    summaryRes.fold(
      (f) => emit(HelperRatingsError(f.message)),
      (summary) {
        reviewsRes.fold(
          (f) => emit(HelperRatingsError(f.message)),
          (reviews) {
            emit(HelperRatingsLoaded(
              reviews: reviews,
              summary: summary,
              hasReachedMax: reviews.length < _pageSize,
            ));
          },
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state is! HelperRatingsLoaded) return;
    final currentState = state as HelperRatingsLoaded;
    if (currentState.hasReachedMax) return;

    _currentPage++;
    final result = await getReceivedRatingsUseCase(page: _currentPage, pageSize: _pageSize);

    result.fold(
      (f) => null, // Silently fail for pagination
      (newReviews) {
        if (newReviews.isEmpty) {
          emit(HelperRatingsLoaded(
            reviews: currentState.reviews,
            summary: currentState.summary,
            hasReachedMax: true,
          ));
        } else {
          emit(HelperRatingsLoaded(
            reviews: [...currentState.reviews, ...newReviews],
            summary: currentState.summary,
            hasReachedMax: newReviews.length < _pageSize,
          ));
        }
      },
    );
  }

  Future<void> refresh() => load();
}

// ── RateUserCubit ────────────────────────────────────────────────────────────

abstract class RateUserState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RateUserInitial extends RateUserState {}

class RateUserSubmitting extends RateUserState {}

class RateUserSuccess extends RateUserState {}

class RateUserError extends RateUserState {
  final String message;
  RateUserError(this.message);

  @override
  List<Object?> get props => [message];
}

class RateUserCubit extends Cubit<RateUserState> {
  final RateUserUseCase rateUserUseCase;

  RateUserCubit({required this.rateUserUseCase}) : super(RateUserInitial());

  Future<void> submitRating({
    required String bookingId,
    required double stars,
    required String comment,
    required List<String> tags,
  }) async {
    emit(RateUserSubmitting());

    final result = await rateUserUseCase(
      bookingId: bookingId,
      stars: stars,
      comment: comment,
      tags: tags,
    );

    result.fold(
      (f) => emit(RateUserError(f.message)),
      (_) => emit(RateUserSuccess()),
    );
  }
}

// ── BookingRatingStateCubit ──────────────────────────────────────────────────

abstract class BookingRatingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BookingRatingInitial extends BookingRatingState {}

class BookingRatingLoading extends BookingRatingState {}

class BookingRatingLoaded extends BookingRatingState {
  final RatingStateEntity stateEntity;
  BookingRatingLoaded(this.stateEntity);

  @override
  List<Object?> get props => [stateEntity];
}

class BookingRatingError extends BookingRatingState {
  final String message;
  BookingRatingError(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingRatingStateCubit extends Cubit<BookingRatingState> {
  final GetBookingRatingStateUseCase getBookingRatingStateUseCase;

  BookingRatingStateCubit({required this.getBookingRatingStateUseCase}) : super(BookingRatingInitial());

  Future<void> loadState(String bookingId) async {
    emit(BookingRatingLoading());
    final result = await getBookingRatingStateUseCase(bookingId);
    result.fold(
      (f) => emit(BookingRatingError(f.message)),
      (s) => emit(BookingRatingLoaded(s)),
    );
  }
}
