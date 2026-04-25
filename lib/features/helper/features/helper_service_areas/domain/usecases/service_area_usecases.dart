import '../entities/service_area_entities.dart';
import '../repositories/service_areas_repository.dart';

class GetServiceAreasUseCase {
  final ServiceAreasRepository repository;
  GetServiceAreasUseCase(this.repository);

  Future<List<ServiceAreaEntity>> execute() => repository.getServiceAreas();
}

class CreateServiceAreaUseCase {
  final ServiceAreasRepository repository;
  CreateServiceAreaUseCase(this.repository);

  Future<ServiceAreaEntity> execute(ServiceAreaEntity area) => repository.createServiceArea(area);
}

class UpdateServiceAreaUseCase {
  final ServiceAreasRepository repository;
  UpdateServiceAreaUseCase(this.repository);

  Future<ServiceAreaEntity> execute(String id, ServiceAreaEntity area) =>
      repository.updateServiceArea(id, area);
}

class DeleteServiceAreaUseCase {
  final ServiceAreasRepository repository;
  DeleteServiceAreaUseCase(this.repository);

  Future<void> execute(String id) => repository.deleteServiceArea(id);
}
