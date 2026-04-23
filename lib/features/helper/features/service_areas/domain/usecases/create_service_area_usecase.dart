import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/service_area_entity.dart';
import '../repositories/service_areas_repository.dart';

class CreateServiceAreaUseCase implements UseCase<ServiceAreaEntity, ServiceAreaEntity> {
  final ServiceAreasRepository repository;

  CreateServiceAreaUseCase(this.repository);

  @override
  Future<Either<Failure, ServiceAreaEntity>> call(ServiceAreaEntity params) {
    return repository.createServiceArea(params);
  }
}
