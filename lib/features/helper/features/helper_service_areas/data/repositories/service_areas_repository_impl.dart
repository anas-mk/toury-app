import '../../domain/entities/service_area_entities.dart';
import '../../domain/repositories/service_areas_repository.dart';
import '../datasources/service_areas_remote_data_source.dart';
import '../models/service_area_models.dart';

class ServiceAreasRepositoryImpl implements ServiceAreasRepository {
  final ServiceAreasRemoteDataSource remoteDataSource;

  ServiceAreasRepositoryImpl({required this.remoteDataSource});

  /// Explicitly map [ServiceAreaModel] to [ServiceAreaEntity] so the UI layer
  /// always receives a clean `List<ServiceAreaEntity>` and never a
  /// `List<ServiceAreaModel>`. This is the root cause of the "firstWhere orElse"
  /// type crash: the runtime list was `List<ServiceAreaModel>`, so the inferred
  /// `orElse` closure type was `() => ServiceAreaModel`, making
  /// `() => ServiceAreaEntity` an incompatible subtype.
  @override
  Future<List<ServiceAreaEntity>> getServiceAreas() async {
    final models = await remoteDataSource.getServiceAreas();
    return models
        .map<ServiceAreaEntity>((m) => ServiceAreaEntity(
              id: m.id,
              country: m.country,
              city: m.city,
              areaName: m.areaName,
              latitude: m.latitude,
              longitude: m.longitude,
              radiusKm: m.radiusKm,
              isPrimary: m.isPrimary,
              createdAt: m.createdAt,
            ))
        .toList();
  }

  @override
  Future<ServiceAreaEntity> createServiceArea(ServiceAreaEntity area) async {
    final model = await remoteDataSource.createServiceArea(ServiceAreaModel.fromEntity(area));
    return ServiceAreaEntity(
      id: model.id,
      country: model.country,
      city: model.city,
      areaName: model.areaName,
      latitude: model.latitude,
      longitude: model.longitude,
      radiusKm: model.radiusKm,
      isPrimary: model.isPrimary,
      createdAt: model.createdAt,
    );
  }

  @override
  Future<ServiceAreaEntity> updateServiceArea(String id, ServiceAreaEntity area) async {
    final model = await remoteDataSource.updateServiceArea(id, ServiceAreaModel.fromEntity(area));
    return ServiceAreaEntity(
      id: model.id,
      country: model.country,
      city: model.city,
      areaName: model.areaName,
      latitude: model.latitude,
      longitude: model.longitude,
      radiusKm: model.radiusKm,
      isPrimary: model.isPrimary,
      createdAt: model.createdAt,
    );
  }

  @override
  Future<void> deleteServiceArea(String id) => remoteDataSource.deleteServiceArea(id);
}
