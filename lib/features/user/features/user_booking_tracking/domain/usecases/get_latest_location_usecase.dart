import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import 'package:toury/core/models/tracking/tracking_point_entity.dart';
import '../repositories/tracking_repository.dart';

/// Returns the latest helper position for [bookingId], or `null`
/// when no GPS sample has been recorded yet (which is normal in the
/// brief window right after the helper accepts).
///
/// We do NOT extend the generic [UseCase] interface here because that
/// interface mandates a non-nullable success type — and "no sample
/// yet" is a perfectly valid success outcome we want callers to
/// handle gracefully (show a "Heading your way" placeholder instead
/// of a red error).
class GetLatestLocationUseCase {
  final TrackingRepository repository;

  GetLatestLocationUseCase(this.repository);

  Future<Either<Failure, TrackingPointEntity?>> call(String bookingId) {
    return repository.getLatestLocation(bookingId);
  }
}
