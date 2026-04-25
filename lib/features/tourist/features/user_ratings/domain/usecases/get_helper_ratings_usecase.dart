import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/rating_entity.dart';
import '../repositories/rating_repository.dart';

class GetHelperRatingsUseCase implements UseCase<List<RatingEntity>, GetHelperRatingsParams> {
  final RatingRepository repository;

  GetHelperRatingsUseCase(this.repository);

  @override
  Future<Either<Failure, List<RatingEntity>>> call(GetHelperRatingsParams params) async {
    return await repository.getHelperRatings(
      params.helperId,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}

class GetHelperRatingsParams {
  final String helperId;
  final int page;
  final int pageSize;

  GetHelperRatingsParams({
    required this.helperId,
    this.page = 1,
    this.pageSize = 10,
  });
}
