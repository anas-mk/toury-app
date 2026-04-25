import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/helper_booking_entity.dart';
import '../../domain/usecases/booking_actions_usecase.dart';

part 'alternatives_state.dart';

class AlternativesCubit extends Cubit<AlternativesState> {
  final GetAlternativesUseCase getAlternativesUseCase;

  AlternativesCubit({
    required this.getAlternativesUseCase,
  }) : super(AlternativesInitial());

  Future<void> getAlternatives(String bookingId) async {
    emit(AlternativesLoading());
    final result = await getAlternativesUseCase(bookingId);
    result.fold(
      (failure) => emit(AlternativesError(failure.message)),
      (helpers) => emit(AlternativesLoaded(helpers)),
    );
  }
}
