import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../repositories/rating_repository.dart';

class RateHelperUseCase implements UseCase<void, RateHelperParams> {
  final RatingRepository repository;

  RateHelperUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RateHelperParams params) async {
    return await repository.rateHelper(
      bookingId: params.bookingId,
      stars: params.stars,
      comment: params.comment,
      tags: params.tags,
    );
  }
}

class RateHelperParams {
  final String bookingId;
  final int stars;
  final String comment;
  final List<String> tags;

  RateHelperParams({
    required this.bookingId,
    required this.stars,
    required this.comment,
    required this.tags,
  });
}
