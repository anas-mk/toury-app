import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import 'package:toury/core/models/tracking/tracking_point_entity.dart';
import 'package:toury/core/models/tracking/tracking_update.dart';

abstract class TrackingRepository {
  /// Returns the latest helper position, or `null` when the helper
  /// hasn't streamed any GPS sample yet (the brief window between
  /// accept and the first throttled sample).
  Future<Either<Failure, TrackingPointEntity?>> getLatestLocation(
    String bookingId,
  );
  Future<Either<Failure, List<TrackingPointEntity>>> getTrackingHistory(
    String bookingId,
  );
  Stream<TrackingUpdate> listenToTrackingUpdates(String bookingId);
}
