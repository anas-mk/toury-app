import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/service_area_entity.dart';
import '../repositories/service_areas_repository.dart';

class GetServiceAreasUseCase implements UseCase<List<ServiceAreaEntity>, NoParams> {
  final ServiceAreasRepository repository;

  GetServiceAreasUseCase(this.repository);

  @override
  Future<Either<Failure, List<ServiceAreaEntity>>> call(NoParams params) {
    return repository.getServiceAreas();
  }
}
