import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/helper_profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase implements UseCase<HelperProfileEntity, NoParams> {
  final ProfileRepository repository;
  GetProfileUseCase(this.repository);

  @override
  Future<Either<Failure, HelperProfileEntity>> call(
    NoParams params, {
    CancelToken? cancelToken,
  }) {
    return repository.getProfile(cancelToken: cancelToken);
  }
}
