import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../domain/usecases/get_booking_details_usecase.dart';
import '../../domain/usecases/get_my_bookings_usecase.dart';
import '../../domain/usecases/booking_actions_usecase.dart';
import 'booking_status_state.dart';

class BookingStatusCubit extends Cubit<BookingStatusState> {
  final GetBookingStatusUseCase getBookingStatusUseCase;
  final GetMyBookingsUseCase getMyBookingsUseCase;
  final GetBookingDetailsUseCase getBookingDetailsUseCase;
  final BookingTrackingHubService hubService;

  StreamSubscription? _statusSubscription;

  BookingStatusCubit({
    required this.getBookingStatusUseCase,
    required this.getMyBookingsUseCase,
    required this.getBookingDetailsUseCase,
    required this.hubService,
  }) : super(BookingStatusInitial());

  Future<void> startPollingForActive() async {
    emit(BookingStatusLoading());
    
    // First, check if there's any active booking using the usecase
    // We can use getMyBookings with 'Active' status or similar
    final result = await getMyBookingsUseCase(status: 'Active', pageSize: 1);
    
    result.fold(
      (failure) => emit(BookingStatusError(failure.message)),
      (pagedResponse) {
        if (pagedResponse.items.isNotEmpty) {
          final activeBooking = pagedResponse.items.first;
          emit(BookingStatusActive(activeBooking));
          _subscribeToStatusChanges(activeBooking.id);
        } else {
          emit(BookingStatusNoActive());
        }
      },
    );
  }

  void _subscribeToStatusChanges(String bookingId) {
    _statusSubscription?.cancel();
    _statusSubscription = hubService.statusStream.listen((event) {
      final String? eventBookingId = event['bookingId']?.toString();
      if (eventBookingId == bookingId) {
        // Refresh booking details when status changes
        refreshActiveBooking(bookingId);
      }
    });
  }

  Future<void> refreshActiveBooking(String bookingId) async {
    final result = await getBookingDetailsUseCase(bookingId);
    result.fold(
      (failure) => emit(BookingStatusError(failure.message)),
      (booking) {
        // Check if booking is still active/upcoming
        const inactiveStatuses = ['Completed', 'Cancelled', 'Declined', 'Expired'];
        if (inactiveStatuses.contains(booking.status.name)) {
          emit(BookingStatusNoActive());
          _statusSubscription?.cancel();
        } else {
          emit(BookingStatusActive(booking));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
}
