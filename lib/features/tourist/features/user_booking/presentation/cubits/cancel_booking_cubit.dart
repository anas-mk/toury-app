import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/booking_actions_usecase.dart';

part 'cancel_booking_state.dart';

class CancelBookingCubit extends Cubit<CancelBookingState> {
  final CancelBookingUseCase cancelBookingUseCase;

  CancelBookingCubit({
    required this.cancelBookingUseCase,
  }) : super(CancelBookingInitial());

  Future<void> cancelBooking(String bookingId, String reason) async {
    emit(CancelBookingLoading());
    final result = await cancelBookingUseCase(bookingId, reason);
    result.fold(
      (failure) => emit(CancelBookingError(failure.message)),
      (_) => emit(CancelBookingSuccess()),
    );
  }
}
