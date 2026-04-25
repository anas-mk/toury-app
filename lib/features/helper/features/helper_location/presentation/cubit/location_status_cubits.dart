import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/helper_location_entities.dart';
import '../../domain/usecases/helper_location_usecases.dart';

// ── LocationStatusCubit ──────────────────────────────────────────────────────

abstract class LocationStatusState extends Equatable {
  const LocationStatusState();
  @override
  List<Object?> get props => [];
}

class LocationStatusInitial extends LocationStatusState {}
class LocationStatusLoading extends LocationStatusState {}
class LocationStatusLoaded extends LocationStatusState {
  final LocationStatus status;
  const LocationStatusLoaded(this.status);
  @override
  List<Object?> get props => [status];
}
class LocationStatusError extends LocationStatusState {
  final String message;
  const LocationStatusError(this.message);
  @override
  List<Object?> get props => [message];
}

class LocationStatusCubit extends Cubit<LocationStatusState> {
  final GetLocationStatusUseCase getStatusUseCase;

  LocationStatusCubit({required this.getStatusUseCase}) : super(LocationStatusInitial());

  Future<void> loadStatus() async {
    emit(LocationStatusLoading());
    try {
      final status = await getStatusUseCase.execute();
      emit(LocationStatusLoaded(status));
    } catch (e) {
      emit(LocationStatusError(e.toString()));
    }
  }
}

// ── EligibilityCubit ─────────────────────────────────────────────────────────

abstract class EligibilityState extends Equatable {
  const EligibilityState();
  @override
  List<Object?> get props => [];
}

class EligibilityInitial extends EligibilityState {}
class EligibilityLoading extends EligibilityState {}
class EligibilityLoaded extends EligibilityState {
  final InstantEligibility eligibility;
  const EligibilityLoaded(this.eligibility);
  @override
  List<Object?> get props => [eligibility];
}
class EligibilityError extends EligibilityState {
  final String message;
  const EligibilityError(this.message);
  @override
  List<Object?> get props => [message];
}

class EligibilityCubit extends Cubit<EligibilityState> {
  final GetInstantEligibilityUseCase getEligibilityUseCase;

  EligibilityCubit({required this.getEligibilityUseCase}) : super(EligibilityInitial());

  Future<void> loadEligibility() async {
    emit(EligibilityLoading());
    try {
      final eligibility = await getEligibilityUseCase.execute();
      emit(EligibilityLoaded(eligibility));
    } catch (e) {
      emit(EligibilityError(e.toString()));
    }
  }
}
