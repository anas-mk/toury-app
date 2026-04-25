import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../../domain/usecases/create_booking_usecase.dart';

part 'scheduled_booking_state.dart';

class ScheduledBookingCubit extends Cubit<ScheduledBookingState> {
  final CreateScheduledBookingUseCase createScheduledBookingUseCase;

  ScheduledBookingCubit({
    required this.createScheduledBookingUseCase,
  }) : super(ScheduledBookingInitial());

  Future<void> createBooking(Map<String, dynamic> bookingData) async {
    emit(ScheduledBookingLoading());
    final result = await createScheduledBookingUseCase(bookingData);
    result.fold(
      (failure) => emit(ScheduledBookingError(failure.message)),
      (booking) => emit(ScheduledBookingSuccess(booking)),
    );
  }
}
