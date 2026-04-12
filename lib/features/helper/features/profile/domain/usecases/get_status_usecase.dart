import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/helper_status_entity.dart';
import '../repositories/profile_repository.dart';

class GetStatusUseCase implements UseCase<HelperStatusEntity, NoParams> {
  final ProfileRepository repository;
  GetStatusUseCase(this.repository);

  @override
  Future<Either<Failure, HelperStatusEntity>> call(
    NoParams params, {
    CancelToken? cancelToken,
  }) {
    return repository.getStatus(cancelToken: cancelToken);
  }
}
