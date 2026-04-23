import 'package:equatable/equatable.dart';
import '../../domain/entities/service_area_entity.dart';

abstract class HelperServiceAreasState extends Equatable {
  const HelperServiceAreasState();

  @override
  List<Object?> get props => [];
}

class HelperServiceAreasInitial extends HelperServiceAreasState {}

class HelperServiceAreasLoading extends HelperServiceAreasState {}

class HelperServiceAreasLoaded extends HelperServiceAreasState {
  final List<ServiceAreaEntity> serviceAreas;

  const HelperServiceAreasLoaded(this.serviceAreas);

  @override
  List<Object?> get props => [serviceAreas];
}

class HelperServiceAreasCreating extends HelperServiceAreasState {}

class HelperServiceAreasUpdating extends HelperServiceAreasState {}

class HelperServiceAreasDeleting extends HelperServiceAreasState {}

class HelperServiceAreasError extends HelperServiceAreasState {
  final String message;

  const HelperServiceAreasError(this.message);

  @override
  List<Object?> get props => [message];
}
