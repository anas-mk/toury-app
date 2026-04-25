import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/rating_entity.dart';
import '../repositories/rating_repository.dart';

class GetUserRatingSummaryUseCase implements UseCase<RatingSummaryEntity, String> {
  final RatingRepository repository;

  GetUserRatingSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, RatingSummaryEntity>> call(String userId) async {
    return await repository.getUserRatingSummary(userId);
  }
}
