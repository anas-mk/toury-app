import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/rating_entity.dart';
import '../../domain/repositories/rating_repository.dart';
import '../datasources/rating_remote_datasource.dart';

class RatingRepositoryImpl implements RatingRepository {
  final RatingRemoteDataSource remoteDataSource;

  RatingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> rateHelper({
    required String bookingId,
    required int stars,
    required String comment,
    required List<String> tags,
  }) async {
    try {
      await remoteDataSource.rateHelper(
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
  Future<Either<Failure, Map<String, dynamic>>> getBookingRatingState(String bookingId) async {
    try {
      final state = await remoteDataSource.getBookingRatingState(bookingId);
      return Right(state);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RatingEntity>>> getHelperRatings(
    String helperId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final ratings = await remoteDataSource.getHelperRatings(helperId, page: page, pageSize: pageSize);
      return Right(ratings);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RatingSummaryEntity>> getHelperRatingSummary(String helperId) async {
    try {
      final summary = await remoteDataSource.getHelperRatingSummary(helperId);
      return Right(summary);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RatingSummaryEntity>> getUserRatingSummary(String userId) async {
    try {
      final summary = await remoteDataSource.getUserRatingSummary(userId);
      return Right(summary);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
