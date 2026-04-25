import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/helper_rating_entities.dart';
import '../repositories/helper_ratings_repository.dart';

class RateUserUseCase {
  final HelperRatingsRepository repository;
  RateUserUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String bookingId,
    required double stars,
    required String comment,
    required List<String> tags,
  }) {
    return repository.rateUser(
      bookingId: bookingId,
      stars: stars,
      comment: comment,
      tags: tags,
    );
  }
}

class GetBookingRatingStateUseCase {
  final HelperRatingsRepository repository;
  GetBookingRatingStateUseCase(this.repository);

  Future<Either<Failure, RatingStateEntity>> call(String bookingId) {
    return repository.getBookingRatingState(bookingId);
  }
}

class GetReceivedRatingsUseCase {
  final HelperRatingsRepository repository;
  GetReceivedRatingsUseCase(this.repository);

  Future<Either<Failure, List<RatingEntity>>> call({int page = 1, int pageSize = 20}) {
    return repository.getReceivedRatings(page: page, pageSize: pageSize);
  }
}

class GetRatingsSummaryUseCase {
  final HelperRatingsRepository repository;
  GetRatingsSummaryUseCase(this.repository);

  Future<Either<Failure, RatingsSummaryEntity>> call() {
    return repository.getRatingsSummary();
  }
}
