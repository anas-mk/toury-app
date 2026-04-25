import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../datasources/tracking_remote_datasource.dart';
import 'package:toury/core/models/tracking/tracking_point_entity.dart';
import '../../domain/repositories/tracking_repository.dart';

class HelperTrackingRepositoryImpl implements HelperTrackingRepository {
  final HelperTrackingRemoteDataSource remoteDataSource;

  HelperTrackingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, TrackingPointEntity>> getLatestLocation(String bookingId) async {
    try {
      final model = await remoteDataSource.getLatestLocation(bookingId);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TrackingPointEntity>>> getTrackingHistory(String bookingId) async {
    try {
      final models = await remoteDataSource.getTrackingHistory(bookingId);
      return Right(models);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
