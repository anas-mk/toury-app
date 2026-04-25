import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import 'package:toury/core/models/tracking/tracking_point_entity.dart';
import '../repositories/tracking_repository.dart';

class GetTrackingHistoryUseCase {
  final HelperTrackingRepository repository;

  GetTrackingHistoryUseCase(this.repository);

  Future<Either<Failure, List<TrackingPointEntity>>> call(String bookingId) {
    return repository.getTrackingHistory(bookingId);
  }
}
