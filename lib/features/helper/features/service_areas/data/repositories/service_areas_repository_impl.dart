import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/service_area_entity.dart';
import '../../domain/repositories/service_areas_repository.dart';
import '../datasources/service_areas_remote_data_source.dart';
import '../models/service_area_model.dart';

class ServiceAreasRepositoryImpl implements ServiceAreasRepository {
  final ServiceAreasRemoteDataSource remoteDataSource;

  ServiceAreasRepositoryImpl({required this.remoteDataSource});

  Failure _mapException(Object e) {
    if (e is ValidationException) return ValidationFailure(e.message);
    if (e is UnauthorizedException) return UnauthorizedFailure(e.message);
    if (e is ForbiddenException) return ForbiddenFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) return ServerFailure(e.message);
    return ServerFailure(e.toString());
  }

  @override
  Future<Either<Failure, List<ServiceAreaEntity>>> getServiceAreas() async {
    try {
      final models = await remoteDataSource.getServiceAreas();
      return Right(models);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, ServiceAreaEntity>> createServiceArea(
    ServiceAreaEntity serviceArea,
  ) async {
    try {
      final model = ServiceAreaModel(
        id: '',
        country: serviceArea.country,
        city: serviceArea.city,
        areaName: serviceArea.areaName,
        latitude: serviceArea.latitude,
        longitude: serviceArea.longitude,
        radiusKm: serviceArea.radiusKm,
        isPrimary: serviceArea.isPrimary,
      );
      final result = await remoteDataSource.createServiceArea(serviceArea: model);
      return Right(result);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, ServiceAreaEntity>> updateServiceArea(
    String id,
    ServiceAreaEntity serviceArea,
  ) async {
    try {
      final model = ServiceAreaModel(
        id: id,
        country: serviceArea.country,
        city: serviceArea.city,
        areaName: serviceArea.areaName,
        latitude: serviceArea.latitude,
        longitude: serviceArea.longitude,
        radiusKm: serviceArea.radiusKm,
        isPrimary: serviceArea.isPrimary,
      );
      final result = await remoteDataSource.updateServiceArea(
        id: id,
        serviceArea: model,
      );
      return Right(result);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteServiceArea(String id) async {
    try {
      await remoteDataSource.deleteServiceArea(id: id);
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }
}
