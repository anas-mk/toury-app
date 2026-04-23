import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_status_entity.dart';
import '../../domain/usecases/create_scheduled_booking_usecase.dart';
import '../../domain/usecases/create_instant_booking_usecase.dart';
import '../../domain/usecases/get_booking_details_usecase.dart';
import '../../domain/usecases/cancel_booking_usecase.dart';
import '../../domain/usecases/get_booking_status_usecase.dart';

abstract class BookingState {}
class BookingInitial extends BookingState {}
class BookingLoading extends BookingState {}
class BookingSuccess extends BookingState {
  final BookingEntity booking;
  BookingSuccess(this.booking);
}
class BookingStatusSuccess extends BookingState {
  final BookingStatusEntity status;
  BookingStatusSuccess(this.status);
}
class BookingCancelled extends BookingState {}
class BookingError extends BookingState {
  final String message;
  BookingError(this.message);
}

class BookingCubit extends Cubit<BookingState> {
  final CreateScheduledBookingUseCase createScheduled;
  final CreateInstantBookingUseCase createInstant;
  final GetBookingDetailsUseCase getDetails;
  final CancelBookingUseCase cancelUseCase;
  final GetBookingStatusUseCase getStatusUseCase;

  BookingCubit({
    required this.createScheduled,
    required this.createInstant,
    required this.getDetails,
    required this.cancelUseCase,
    required this.getStatusUseCase,
  }) : super(BookingInitial());

  Future<void> createScheduledBooking() async {
    emit(BookingLoading());
    final result = await createScheduled();
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (booking) => emit(BookingSuccess(booking)),
    );
  }

  Future<void> createInstantBooking() async {
    emit(BookingLoading());
    final result = await createInstant();
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (booking) => emit(BookingSuccess(booking)),
    );
  }

  Future<void> loadDetails(String bookingId) async {
    emit(BookingLoading());
    final result = await getDetails(bookingId);
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (booking) => emit(BookingSuccess(booking)),
    );
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    emit(BookingLoading());
    final result = await cancelUseCase(CancelBookingParams(bookingId: bookingId, reason: reason));
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (_) => emit(BookingCancelled()),
    );
  }

  Future<void> loadStatus(String bookingId) async {
    emit(BookingLoading());
    final result = await getStatusUseCase(bookingId);
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (status) => emit(BookingStatusSuccess(status)),
    );
  }
}
