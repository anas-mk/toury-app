import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/rating_entity.dart';
import '../repositories/rating_repository.dart';

class GetHelperRatingSummaryUseCase implements UseCase<RatingSummaryEntity, String> {
  final RatingRepository repository;

  GetHelperRatingSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, RatingSummaryEntity>> call(String helperId) async {
    return await repository.getHelperRatingSummary(helperId);
  }
}
