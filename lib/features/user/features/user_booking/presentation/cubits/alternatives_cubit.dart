import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/booking_actions_usecase.dart';
import '../../domain/entities/helper_booking_entity.dart';

abstract class AlternativesState extends Equatable {
  const AlternativesState();
  @override
  List<Object?> get props => [];
}
class AlternativesInitial extends AlternativesState {}
class AlternativesLoading extends AlternativesState {}
class AlternativesLoaded extends AlternativesState {
  final List<HelperBookingEntity> alternatives;
  const AlternativesLoaded(this.alternatives);
  @override
  List<Object?> get props => [alternatives];
}
class AlternativesError extends AlternativesState {
  final String message;
  const AlternativesError(this.message);
  @override
  List<Object?> get props => [message];
}

class AlternativesCubit extends Cubit<AlternativesState> {
  final GetAlternativesUseCase getAlternativesUseCase;

  AlternativesCubit({required this.getAlternativesUseCase}) : super(AlternativesInitial());

  Future<void> loadAlternatives(String bookingId) async {
    emit(AlternativesLoading());
    final result = await getAlternativesUseCase(bookingId);
    result.fold(
      (failure) => emit(AlternativesError(failure.message)),
      (alternatives) => emit(AlternativesLoaded(alternatives)),
    );
  }
}
