import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/get_booking_details_usecase.dart';
import '../../domain/usecases/booking_actions_usecase.dart';
import '../../domain/entities/search_params.dart';
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

  /// Create an instant booking using full search params from the user.
  Future<void> createInstant({
    required InstantSearchParams params,
    String? helperId,
  }) async {
    if (isClosed) return;
    emit(BookingLoading());
    final result = await createInstantBookingUseCase({
      if (helperId != null) 'helperId': helperId,
      'pickupLocationName': params.pickupLocationName,
      'pickupLatitude': params.pickupLatitude,
      'pickupLongitude': params.pickupLongitude,
      'durationInMinutes': params.durationInMinutes,
      'requestedLanguage': params.requestedLanguage,
      'requiresCar': params.requiresCar,
      'travelersCount': params.travelersCount,
    });
    if (isClosed) return;
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (booking) => emit(BookingCreated(booking)),
    );
  }

  /// Create a scheduled booking using full search params from the user.
  Future<void> createScheduled({
    required String helperId,
    required ScheduledSearchParams params,
    String? pickupLocationName,
    double? pickupLatitude,
    double? pickupLongitude,
    String? destinationName,
    double? destinationLatitude,
    double? destinationLongitude,
    double? distanceKm,
    String? notes,
  }) async {
    if (isClosed) return;
    emit(BookingLoading());
    final result = await createScheduledBookingUseCase({
      'helperId': helperId,
      'destinationCity': params.destinationCity,
      'requestedDate': params.requestedDate.toIso8601String(),
      'startTime': params.startTime,
      'durationInMinutes': params.durationInMinutes,
      'requestedLanguage': params.requestedLanguage,
      'requiresCar': params.requiresCar,
      'travelersCount': params.travelersCount,
      if (pickupLocationName != null) 'pickupLocationName': pickupLocationName,
      if (pickupLatitude != null) 'pickupLatitude': pickupLatitude,
      if (pickupLongitude != null) 'pickupLongitude': pickupLongitude,
      if (destinationName != null) 'destinationName': destinationName,
      if (destinationLatitude != null) 'destinationLatitude': destinationLatitude,
      if (destinationLongitude != null) 'destinationLongitude': destinationLongitude,
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (notes != null) 'notes': notes,
    });
    if (isClosed) return;
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (booking) => emit(BookingCreated(booking)),
    );
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    if (isClosed) return;
    emit(BookingLoading());
    final result = await cancelBookingUseCase(bookingId, reason);
    if (isClosed) return;
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (_) => emit(BookingCancelled()),
    );
  }
}
