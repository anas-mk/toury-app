import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/alternatives_response.dart';
import '../../../domain/usecases/instant/get_alternatives_uc.dart';

abstract class ScheduledAlternativesState extends Equatable {
  const ScheduledAlternativesState();
  @override
  List<Object?> get props => [];
}

class ScheduledAlternativesInitial extends ScheduledAlternativesState {
  const ScheduledAlternativesInitial();
}

class ScheduledAlternativesLoading extends ScheduledAlternativesState {
  const ScheduledAlternativesLoading();
}

class ScheduledAlternativesLoaded extends ScheduledAlternativesState {
  final AlternativesResponse data;
  const ScheduledAlternativesLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class ScheduledAlternativesError extends ScheduledAlternativesState {
  final String message;
  const ScheduledAlternativesError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Reuses [GetAlternativesUC] (originally written for the instant flow)
/// because the REST endpoint
/// `GET /api/user/bookings/{id}/alternatives` is shared between flows
/// and already returns the full `AlternativesResponse` (history,
/// auto-retry status, attempt counters, alternative helpers).
///
/// We keep this cubit separate from the legacy [`AlternativesCubit`]
/// (which exposes only `List<HelperBookingEntity>`) to avoid breaking
/// the older instant pages that still consume the trimmed response.
class ScheduledAlternativesCubit extends Cubit<ScheduledAlternativesState> {
  ScheduledAlternativesCubit({required this.getAlternativesUC})
      : super(const ScheduledAlternativesInitial());

  final GetAlternativesUC getAlternativesUC;

  Future<void> load(String bookingId) async {
    if (isClosed) return;
    emit(const ScheduledAlternativesLoading());
    final result = await getAlternativesUC(bookingId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ScheduledAlternativesError(failure.message)),
      (data) => emit(ScheduledAlternativesLoaded(data)),
    );
  }

  /// Pulled by pull-to-refresh and after the user picks a new helper.
  Future<void> refresh(String bookingId) => load(bookingId);
}
