import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../datasources/helper_ratings_service.dart';
import '../../domain/entities/rating_entities.dart';

abstract class HelperRatingsRepository {
  Future<Either<Failure, Unit>> submitUserRating(String bookingId, int stars, String? comment, List<String> tags);
  Future<Either<Failure, RatingStatusEntity>> getBookingRatingStatus(String bookingId);
  Future<Either<Failure, List<RatingEntity>>> getReceivedRatings({int page = 1, int pageSize = 20});
  Future<Either<Failure, RatingSummaryEntity>> getRatingsSummary();
}

class HelperRatingsRepositoryImpl implements HelperRatingsRepository {
  final HelperRatingsService service;
  HelperRatingsRepositoryImpl(this.service);

  @override
  Future<Either<Failure, Unit>> submitUserRating(String bookingId, int stars, String? comment, List<String> tags) async {
    try {
      await service.submitUserRating(bookingId, stars, comment, tags);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RatingStatusEntity>> getBookingRatingStatus(String bookingId) async {
    try {
      final result = await service.getBookingRatingStatus(bookingId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RatingEntity>>> getReceivedRatings({int page = 1, int pageSize = 20}) async {
    try {
      final result = await service.getReceivedRatings(page: page, pageSize: pageSize);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RatingSummaryEntity>> getRatingsSummary() async {
    try {
      final result = await service.getRatingsSummary();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
