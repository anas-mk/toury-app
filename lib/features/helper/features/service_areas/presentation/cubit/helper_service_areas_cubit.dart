import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../../domain/entities/service_area_entity.dart';
import '../../domain/usecases/create_service_area_usecase.dart';
import '../../domain/usecases/delete_service_area_usecase.dart';
import '../../domain/usecases/get_service_areas_usecase.dart';
import '../../domain/usecases/update_service_area_usecase.dart';
import 'helper_service_areas_state.dart';

class HelperServiceAreasCubit extends Cubit<HelperServiceAreasState> {
  final GetServiceAreasUseCase getServiceAreasUseCase;
  final CreateServiceAreaUseCase createServiceAreaUseCase;
  final UpdateServiceAreaUseCase updateServiceAreaUseCase;
  final DeleteServiceAreaUseCase deleteServiceAreaUseCase;

  HelperServiceAreasCubit({
    required this.getServiceAreasUseCase,
    required this.createServiceAreaUseCase,
    required this.updateServiceAreaUseCase,
    required this.deleteServiceAreaUseCase,
  }) : super(HelperServiceAreasInitial());

  Future<void> getServiceAreas() async {
    emit(HelperServiceAreasLoading());
    final result = await getServiceAreasUseCase(NoParams());
    result.fold(
      (failure) => emit(HelperServiceAreasError(failure.message)),
      (areas) => emit(HelperServiceAreasLoaded(areas)),
    );
  }

  Future<void> createServiceArea(ServiceAreaEntity serviceArea) async {
    emit(HelperServiceAreasCreating());
    final result = await createServiceAreaUseCase(serviceArea);
    result.fold(
      (failure) => emit(HelperServiceAreasError(failure.message)),
      (_) => getServiceAreas(), // Refresh list after creation
    );
  }

  Future<void> updateServiceArea(String id, ServiceAreaEntity serviceArea) async {
    emit(HelperServiceAreasUpdating());
    final result = await updateServiceAreaUseCase(
      UpdateServiceAreaParams(id: id, serviceArea: serviceArea),
    );
    result.fold(
      (failure) => emit(HelperServiceAreasError(failure.message)),
      (_) => getServiceAreas(), // Refresh list after update
    );
  }

  Future<void> deleteServiceArea(String id) async {
    emit(HelperServiceAreasDeleting());
    final result = await deleteServiceAreaUseCase(id);
    result.fold(
      (failure) => emit(HelperServiceAreasError(failure.message)),
      (_) => getServiceAreas(), // Refresh list after deletion
    );
  }
}
