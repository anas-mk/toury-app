import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/helper_eligibility_entity.dart';
import '../repositories/profile_repository.dart';

class CheckEligibilityUseCase implements UseCase<HelperEligibilityEntity, NoParams> {
  final ProfileRepository repository;
  CheckEligibilityUseCase(this.repository);

  @override
  Future<Either<Failure, HelperEligibilityEntity>> call(
    NoParams params, {
    CancelToken? cancelToken,
  }) {
    return repository.checkEligibility(cancelToken: cancelToken);
  }
}
