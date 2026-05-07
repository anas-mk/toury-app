import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import 'package:toury/core/models/tracking/tracking_point_entity.dart';
import '../repositories/tracking_repository.dart';

class GetLatestLocationUseCase implements UseCase<TrackingPointEntity, String> {
  final TrackingRepository repository;

  GetLatestLocationUseCase(this.repository);

  @override
  Future<Either<Failure, TrackingPointEntity>> call(String bookingId) async {
    return await repository.getLatestLocation(bookingId);
  }
}
