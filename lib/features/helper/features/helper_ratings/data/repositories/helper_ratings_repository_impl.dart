import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/helper_rating_entities.dart';
import '../../domain/repositories/helper_ratings_repository.dart';
import '../datasources/helper_ratings_remote_data_source.dart';

class HelperRatingsRepositoryImpl implements HelperRatingsRepository {
  final HelperRatingsRemoteDataSource remoteDataSource;

  HelperRatingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> rateUser({
    required String bookingId,
    required double stars,
    required String comment,
    required List<String> tags,
  }) async {
    try {
      await remoteDataSource.rateUser(
        bookingId: bookingId,
        stars: stars,
        comment: comment,
        tags: tags,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RatingStateEntity>> getBookingRatingState(String bookingId) async {
    try {
      final result = await remoteDataSource.getBookingRatingState(bookingId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RatingEntity>>> getReceivedRatings({int page = 1, int pageSize = 20}) async {
    try {
      final result = await remoteDataSource.getReceivedRatings(page: page, pageSize: pageSize);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RatingsSummaryEntity>> getRatingsSummary() async {
    try {
      final result = await remoteDataSource.getRatingsSummary();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
