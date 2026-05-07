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
  bool _inFlight = false;
  DateTime? _lastFetchAt;
  static const Duration _minFetchInterval = Duration(seconds: 8);

  LocationStatusCubit({required this.getStatusUseCase}) : super(LocationStatusInitial());

  Future<void> loadStatus({bool force = false}) async {
    if (_inFlight) return;
    if (!force && _lastFetchAt != null) {
      final diff = DateTime.now().difference(_lastFetchAt!);
      if (diff < _minFetchInterval) return;
    }

    _inFlight = true;
    if (state is! LocationStatusLoaded) {
      emit(LocationStatusLoading());
    }
    try {
      final status = await getStatusUseCase.execute();
      _lastFetchAt = DateTime.now();
      emit(LocationStatusLoaded(status));
    } catch (e) {
      emit(LocationStatusError(e.toString()));
    } finally {
      _inFlight = false;
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

  Future<void> loadEligibility({
    double? pickupLat,
    double? pickupLng,
    String? language,
    bool? requiresCar,
  }) async {
    emit(EligibilityLoading());
    try {
      final eligibility = await getEligibilityUseCase.execute(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        language: language,
        requiresCar: requiresCar,
      );
      emit(EligibilityLoaded(eligibility));
    } catch (e) {
      emit(EligibilityError(e.toString()));
    }
  }
}