import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/get_booking_details_usecase.dart';
import '../../domain/usecases/booking_actions_usecase.dart';
import 'booking_state.dart';

/// Scheduled-flow cubit only.
///
/// The Instant flow now lives in [`InstantBookingCubit`] with a proper
/// state machine and SignalR wiring. The old `createInstant` method on
/// this cubit was deleted (it hardcoded language/duration in violation
/// of the rebuild contract) — see `InstantBookingCubit.createBooking`
/// for the replacement.
class BookingCubit extends Cubit<BookingState> {
  final CreateScheduledBookingUseCase createScheduledBookingUseCase;
  final GetBookingDetailsUseCase getBookingDetailsUseCase;
  final CancelBookingUseCase cancelBookingUseCase;
  final GetAlternativesUseCase getAlternativesUseCase;

  BookingCubit({
    required this.createScheduledBookingUseCase,
    required this.getBookingDetailsUseCase,
    required this.cancelBookingUseCase,
    required this.getAlternativesUseCase,
  }) : super(BookingInitial());

  Future<void> createScheduled({
    required String helperId,
    required String destinationCity,
    required DateTime requestedDate,
    required String startTime,
    required int durationInMinutes,
  }) async {
    emit(BookingLoading());
    final result = await createScheduledBookingUseCase({
      'helperId': helperId,
      'destinationCity': destinationCity,
      'requestedDate': requestedDate.toIso8601String(),
      'startTime': startTime,
      'durationInMinutes': durationInMinutes,
      'requestedLanguage': 'English',
      'requiresCar': false,
      'travelersCount': 1,
    });
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (booking) => emit(BookingCreated(booking)),
    );
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    emit(BookingLoading());
    final result = await cancelBookingUseCase(bookingId, reason);
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (_) => emit(BookingCancelled()),
    );
  }
}
