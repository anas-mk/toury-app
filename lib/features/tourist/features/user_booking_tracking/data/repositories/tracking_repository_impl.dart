import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import 'package:toury/core/models/tracking/tracking_point_entity.dart';
import 'package:toury/core/models/tracking/tracking_update.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/tracking_remote_datasource.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingRemoteDataSource remoteDataSource;
  final BookingTrackingHubService hubService;

  TrackingRepositoryImpl({
    required this.remoteDataSource,
    required this.hubService,
  });

  @override
  Future<Either<Failure, TrackingPointEntity>> getLatestLocation(String bookingId) async {
    try {
      final point = await remoteDataSource.getLatestLocation(bookingId);
      return Right(point);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TrackingPointEntity>>> getTrackingHistory(String bookingId) async {
    try {
      final history = await remoteDataSource.getTrackingHistory(bookingId);
      return Right(history);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<TrackingUpdate> listenToTrackingUpdates(String bookingId) {
    // Note: In a real app, we might want to ensure connection is established
    // but the Cubit will handle the connect() call.
    return hubService.updateStream;
  }
}
