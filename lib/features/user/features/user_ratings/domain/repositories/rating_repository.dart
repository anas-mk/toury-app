import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/rating_entity.dart';

abstract class RatingRepository {
  Future<Either<Failure, void>> rateHelper({
    required String bookingId,
    required int stars,
    required String comment,
    required List<String> tags,
  });

  Future<Either<Failure, Map<String, dynamic>>> getBookingRatingState(String bookingId);

  Future<Either<Failure, List<RatingEntity>>> getHelperRatings(
    String helperId, {
    int page = 1,
    int pageSize = 10,
  });

  Future<Either<Failure, RatingSummaryEntity>> getHelperRatingSummary(String helperId);

  Future<Either<Failure, RatingSummaryEntity>> getUserRatingSummary(String userId);
}
