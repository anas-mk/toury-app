import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import 'package:toury/core/models/tracking/tracking_point_entity.dart';
import '../repositories/tracking_repository.dart';

class GetLatestLocationUseCase {
  final HelperTrackingRepository repository;

  GetLatestLocationUseCase(this.repository);

  Future<Either<Failure, TrackingPointEntity>> call(String bookingId) {
    return repository.getLatestLocation(bookingId);
  }
}
