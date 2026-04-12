import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../repositories/profile_repository.dart';

class DeleteCarUseCase implements UseCase<Unit, NoParams> {
  final ProfileRepository repository;
  DeleteCarUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(
    NoParams params, {
    CancelToken? cancelToken,
  }) {
    return repository.deleteCar(cancelToken: cancelToken);
  }
}
