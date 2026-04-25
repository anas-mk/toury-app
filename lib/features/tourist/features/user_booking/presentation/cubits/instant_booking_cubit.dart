import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../../domain/entities/helper_booking_entity.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/booking_actions_usecase.dart';

part 'instant_booking_state.dart';

class InstantBookingCubit extends Cubit<InstantBookingState> {
  final CreateInstantBookingUseCase createInstantBookingUseCase;
  final GetBookingStatusUseCase getBookingStatusUseCase;

  InstantBookingCubit({
    required this.createInstantBookingUseCase,
    required this.getBookingStatusUseCase,
  }) : super(InstantBookingInitial());

  Future<void> createInstantBooking(Map<String, dynamic> bookingData) async {
    emit(InstantBookingLoading());
    final result = await createInstantBookingUseCase(bookingData);
    result.fold(
      (failure) => emit(InstantBookingError(failure.message)),
      (booking) => emit(InstantBookingWaitingResponse(booking)),
    );
  }

  void updateStatus(String status) {
    if (state is InstantBookingWaitingResponse) {
      final booking = (state as InstantBookingWaitingResponse).booking;
      if (status.toLowerCase() == 'confirmed') {
        emit(InstantBookingConfirmed(booking));
      } else if (status.toLowerCase() == 'declined' || status.toLowerCase() == 'cancelled') {
        emit(InstantBookingDeclined(booking));
      }
    }
  }
}
