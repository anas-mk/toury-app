import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/service_area_entities.dart';
import '../../domain/usecases/service_area_usecases.dart';

abstract class ServiceAreasState extends Equatable {
  const ServiceAreasState();
  @override
  List<Object?> get props => [];
}

class ServiceAreasInitial extends ServiceAreasState {}
class ServiceAreasLoading extends ServiceAreasState {}
class ServiceAreasLoaded extends ServiceAreasState {
  final List<ServiceAreaEntity> areas;
  const ServiceAreasLoaded(this.areas);
  @override
  List<Object?> get props => [areas];
}
class ServiceAreasEmpty extends ServiceAreasState {}
class ServiceAreasError extends ServiceAreasState {
  final String message;
  const ServiceAreasError(this.message);
  @override
  List<Object?> get props => [message];
}

class ServiceAreaOperationLoading extends ServiceAreasState {}
class ServiceAreaOperationSuccess extends ServiceAreasState {
  final String message;
  const ServiceAreaOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class ServiceAreasCubit extends Cubit<ServiceAreasState> {
  final GetServiceAreasUseCase getAreasUseCase;
  final CreateServiceAreaUseCase createAreaUseCase;
  final UpdateServiceAreaUseCase updateAreaUseCase;
  final DeleteServiceAreaUseCase deleteAreaUseCase;

  ServiceAreasCubit({
    required this.getAreasUseCase,
    required this.createAreaUseCase,
    required this.updateAreaUseCase,
    required this.deleteAreaUseCase,
  }) : super(ServiceAreasInitial());

  Future<void> loadAreas() async {
    emit(ServiceAreasLoading());
    try {
      final areas = await getAreasUseCase.execute();
      if (isClosed) return;
      if (areas.isEmpty) {
        emit(ServiceAreasEmpty());
      } else {
        emit(ServiceAreasLoaded(areas));
      }
    } catch (e) {
      if (isClosed) return;
      emit(ServiceAreasError(e.toString()));
    }
  }

  Future<void> addArea(ServiceAreaEntity area) async {
    emit(ServiceAreaOperationLoading());
    try {
      await createAreaUseCase.execute(area);
      if (isClosed) return;
      emit(const ServiceAreaOperationSuccess('Service area added successfully'));
      await loadAreas();
    } catch (e) {
      if (isClosed) return;
      emit(ServiceAreasError(e.toString()));
    }
  }

  Future<void> updateArea(String id, ServiceAreaEntity area) async {
    emit(ServiceAreaOperationLoading());
    try {
      await updateAreaUseCase.execute(id, area);
      if (isClosed) return;
      emit(const ServiceAreaOperationSuccess('Service area updated successfully'));
      await loadAreas();
    } catch (e) {
      if (isClosed) return;
      emit(ServiceAreasError(e.toString()));
    }
  }

  Future<void> deleteArea(String id) async {
    emit(ServiceAreaOperationLoading());
    try {
      await deleteAreaUseCase.execute(id);
      if (isClosed) return;
      emit(const ServiceAreaOperationSuccess('Service area removed'));
      await loadAreas();
    } catch (e) {
      if (isClosed) return;
      emit(ServiceAreasError(e.toString()));
    }
  }
}
