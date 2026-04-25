import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import 'package:toury/core/models/tracking/tracking_point_entity.dart';
import '../repositories/tracking_repository.dart';

class GetTrackingHistoryUseCase implements UseCase<List<TrackingPointEntity>, String> {
  final TrackingRepository repository;

  GetTrackingHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<TrackingPointEntity>>> call(String bookingId) async {
    return await repository.getTrackingHistory(bookingId);
  }
}
