import 'package:dartz/dartz.dart';
import 'package:toury/core/errors/failures.dart';
import '../entities/helper_rating_entities.dart';

abstract class HelperRatingsRepository {
  Future<Either<Failure, void>> rateUser({
    required String bookingId,
    required double stars,
    required String comment,
    required List<String> tags,
  });

  Future<Either<Failure, RatingStateEntity>> getBookingRatingState(String bookingId);

  Future<Either<Failure, List<RatingEntity>>> getReceivedRatings({
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, RatingsSummaryEntity>> getRatingsSummary();
}
