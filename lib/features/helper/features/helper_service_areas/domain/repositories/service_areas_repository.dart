import '../entities/service_area_entities.dart';

abstract class ServiceAreasRepository {
  Future<List<ServiceAreaEntity>> getServiceAreas();
  Future<ServiceAreaEntity> createServiceArea(ServiceAreaEntity area);
  Future<ServiceAreaEntity> updateServiceArea(String id, ServiceAreaEntity area);
  Future<void> deleteServiceArea(String id);
}
