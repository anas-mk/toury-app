import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_helper_rating_summary_usecase.dart';
import '../../domain/usecases/get_helper_ratings_usecase.dart';
import '../../domain/usecases/rate_helper_usecase.dart';
import 'user_ratings_state.dart';

class UserRatingsCubit extends Cubit<UserRatingsState> {
  final RateHelperUseCase rateHelperUseCase;
  final GetHelperRatingsUseCase getHelperRatingsUseCase;
  final GetHelperRatingSummaryUseCase getHelperRatingSummaryUseCase;

  UserRatingsCubit({
    required this.rateHelperUseCase,
    required this.getHelperRatingsUseCase,
    required this.getHelperRatingSummaryUseCase,
  }) : super(UserRatingsInitial());

  Future<void> loadHelperRatings(String helperId) async {
    emit(RatingLoading());
    final summaryResult = await getHelperRatingSummaryUseCase(helperId);
    final ratingsResult = await getHelperRatingsUseCase(GetHelperRatingsParams(helperId: helperId));

    summaryResult.fold(
      (failure) => emit(RatingError(failure.message)),
      (summary) {
        ratingsResult.fold(
          (failure) => emit(RatingError(failure.message)),
          (ratings) => emit(RatingLoaded(ratings: ratings, summary: summary)),
        );
      },
    );
  }

  Future<void> submitRating({
    required String bookingId,
    required int stars,
    required String comment,
    required List<String> tags,
  }) async {
    emit(RatingLoading());
    final result = await rateHelperUseCase(RateHelperParams(
      bookingId: bookingId,
      stars: stars,
      comment: comment,
      tags: tags,
    ));

    result.fold(
      (failure) => emit(RatingError(failure.message)),
      (_) => emit(RatingSuccess()),
    );
  }
}
