import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../repositories/service_areas_repository.dart';

class DeleteServiceAreaUseCase implements UseCase<void, String> {
  final ServiceAreasRepository repository;

  DeleteServiceAreaUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) {
    return repository.deleteServiceArea(params);
  }
}
