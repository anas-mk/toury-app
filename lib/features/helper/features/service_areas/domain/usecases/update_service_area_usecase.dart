import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/service_area_entity.dart';
import '../repositories/service_areas_repository.dart';

class UpdateServiceAreaUseCase implements UseCase<ServiceAreaEntity, UpdateServiceAreaParams> {
  final ServiceAreasRepository repository;

  UpdateServiceAreaUseCase(this.repository);

  @override
  Future<Either<Failure, ServiceAreaEntity>> call(UpdateServiceAreaParams params) {
    return repository.updateServiceArea(params.id, params.serviceArea);
  }
}

class UpdateServiceAreaParams extends Equatable {
  final String id;
  final ServiceAreaEntity serviceArea;

  const UpdateServiceAreaParams({required this.id, required this.serviceArea});

  @override
  List<Object?> get props => [id, serviceArea];
}
