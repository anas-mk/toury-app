import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/get_booking_details_usecase.dart';
import '../../domain/usecases/booking_actions_usecase.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final CreateInstantBookingUseCase createInstantBookingUseCase;
  final CreateScheduledBookingUseCase createScheduledBookingUseCase;
  final GetBookingDetailsUseCase getBookingDetailsUseCase;
  final CancelBookingUseCase cancelBookingUseCase;
  final GetAlternativesUseCase getAlternativesUseCase;

  BookingCubit({
    required this.createInstantBookingUseCase,
    required this.createScheduledBookingUseCase,
    required this.getBookingDetailsUseCase,
    required this.cancelBookingUseCase,
    required this.getAlternativesUseCase,
  }) : super(BookingInitial());

  Future<void> createInstant({
    required String helperId,
    required String pickupLocationName,
    required double pickupLatitude,
    required double pickupLongitude,
  }) async {
    emit(BookingLoading());
    final result = await createInstantBookingUseCase({
      'helperId': helperId,
      'pickupLocationName': pickupLocationName,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'durationInMinutes': 240, // Default 4 hours
      'requestedLanguage': 'English',
      'requiresCar': false,
      'travelersCount': 1,
    });
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (booking) => emit(BookingCreated(booking)),
    );
  }

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
