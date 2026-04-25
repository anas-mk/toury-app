import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import 'package:toury/core/models/tracking/tracking_point_entity.dart';

abstract class HelperTrackingRepository {
  Future<Either<Failure, TrackingPointEntity>> getLatestLocation(String bookingId);
  Future<Either<Failure, List<TrackingPointEntity>>> getTrackingHistory(String bookingId);
}
