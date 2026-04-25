import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/rating_model.dart';
import '../../domain/usecases/rate_helper_usecase.dart';
import '../../domain/usecases/get_booking_rating_state_usecase.dart';
import '../../domain/usecases/get_helper_ratings_usecase.dart';
import '../../domain/usecases/get_helper_rating_summary_usecase.dart';
import '../../domain/usecases/get_user_rating_summary_usecase.dart';
import 'user_ratings_state.dart';

class UserRatingsCubit extends Cubit<UserRatingsState> {
  final RateHelperUseCase rateHelperUseCase;
  final GetBookingRatingStateUseCase getBookingRatingStateUseCase;
  final GetHelperRatingsUseCase getHelperRatingsUseCase;
  final GetHelperRatingSummaryUseCase getHelperRatingSummaryUseCase;
  final GetUserRatingSummaryUseCase getUserRatingSummaryUseCase;

  UserRatingsCubit({
    required this.rateHelperUseCase,
    required this.getBookingRatingStateUseCase,
    required this.getHelperRatingsUseCase,
    required this.getHelperRatingSummaryUseCase,
    required this.getUserRatingSummaryUseCase,
  }) : super(UserRatingsInitial());

  Future<void> rateHelper({
    required String bookingId,
    required int stars,
    required String comment,
    required List<String> tags,
  }) async {
    emit(UserRatingsSubmitting());
    final result = await rateHelperUseCase(RateHelperParams(
      bookingId: bookingId,
      stars: stars,
      comment: comment,
      tags: tags,
    ));

    result.fold(
      (failure) => emit(UserRatingsError(failure.message)),
      (_) => emit(UserRatingsSubmitted()),
    );
  }

  Future<void> getBookingRatingState(String bookingId) async {
    emit(UserRatingsLoading());
    final result = await getBookingRatingStateUseCase(bookingId);

    result.fold(
      (failure) => emit(UserRatingsError(failure.message)),
      (data) {
        final canRate = data['canRate'] ?? false;
        final existingRatingJson = data['rating'];
        final existingRating = existingRatingJson != null ? RatingModel.fromJson(existingRatingJson) : null;
        emit(BookingRatingStateLoaded(canRate: canRate, existingRating: existingRating));
      },
    );
  }

  Future<void> getHelperRatings(String helperId, {int page = 1}) async {
    if (page == 1) emit(UserRatingsLoading());
    final result = await getHelperRatingsUseCase(GetHelperRatingsParams(
      helperId: helperId,
      page: page,
    ));

    result.fold(
      (failure) => emit(UserRatingsError(failure.message)),
      (ratings) => emit(UserRatingsLoaded(ratings: ratings, hasMore: ratings.length == 10)),
    );
  }

  Future<void> getHelperSummary(String helperId) async {
    emit(UserRatingsLoading());
    final result = await getHelperRatingSummaryUseCase(helperId);

    result.fold(
      (failure) => emit(UserRatingsError(failure.message)),
      (summary) => emit(RatingSummaryLoaded(summary)),
    );
  }

  Future<void> getUserSummary(String userId) async {
    emit(UserRatingsLoading());
    final result = await getUserRatingSummaryUseCase(userId);

    result.fold(
      (failure) => emit(UserRatingsError(failure.message)),
      (summary) => emit(RatingSummaryLoaded(summary)),
    );
  }
}
