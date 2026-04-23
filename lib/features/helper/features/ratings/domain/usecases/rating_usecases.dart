import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../data/repositories/helper_ratings_repository_impl.dart';
import '../entities/rating_entities.dart';

class SubmitUserRatingUseCase {
  final HelperRatingsRepository repository;
  SubmitUserRatingUseCase(this.repository);
  Future<Either<Failure, Unit>> call(String bookingId, {required int stars, String? comment, List<String> tags = const []}) =>
      repository.submitUserRating(bookingId, stars, comment, tags);
}

class GetBookingRatingStatusUseCase {
  final HelperRatingsRepository repository;
  GetBookingRatingStatusUseCase(this.repository);
  Future<Either<Failure, RatingStatusEntity>> call(String bookingId) => repository.getBookingRatingStatus(bookingId);
}

class GetReceivedRatingsUseCase {
  final HelperRatingsRepository repository;
  GetReceivedRatingsUseCase(this.repository);
  Future<Either<Failure, List<RatingEntity>>> call({int page = 1, int pageSize = 20}) =>
      repository.getReceivedRatings(page: page, pageSize: pageSize);
}

class GetRatingsSummaryUseCase {
  final HelperRatingsRepository repository;
  GetRatingsSummaryUseCase(this.repository);
  Future<Either<Failure, RatingSummaryEntity>> call() => repository.getRatingsSummary();
}
