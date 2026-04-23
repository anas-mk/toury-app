import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/service_area_entity.dart';

abstract class ServiceAreasRepository {
  Future<Either<Failure, List<ServiceAreaEntity>>> getServiceAreas();
  
  Future<Either<Failure, ServiceAreaEntity>> createServiceArea(
    ServiceAreaEntity serviceArea,
  );
  
  Future<Either<Failure, ServiceAreaEntity>> updateServiceArea(
    String id,
    ServiceAreaEntity serviceArea,
  );
  
  Future<Either<Failure, void>> deleteServiceArea(String id);
}
