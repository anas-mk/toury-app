import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import 'package:toury/core/models/tracking/tracking_point_entity.dart';
import 'package:toury/core/models/tracking/tracking_update.dart';

abstract class TrackingRepository {
  Future<Either<Failure, TrackingPointEntity>> getLatestLocation(String bookingId);
  Future<Either<Failure, List<TrackingPointEntity>>> getTrackingHistory(String bookingId);
  Stream<TrackingUpdate> listenToTrackingUpdates(String bookingId);
}
