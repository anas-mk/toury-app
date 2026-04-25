import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/booking_actions_usecase.dart';
import '../../domain/usecases/get_my_bookings_usecase.dart';
import '../../domain/entities/booking_detail_entity.dart';

part 'booking_status_state.dart';

class BookingStatusCubit extends Cubit<BookingStatusState> {
  final GetBookingStatusUseCase getBookingStatusUseCase;
  final GetMyBookingsUseCase getMyBookingsUseCase;
  Timer? _timer;

  BookingStatusCubit({
    required this.getBookingStatusUseCase,
    required this.getMyBookingsUseCase,
  }) : super(BookingStatusInitial());

  void startPolling(String bookingId) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final result = await getBookingStatusUseCase(bookingId);
      result.fold(
        (failure) => emit(BookingStatusError(failure.message)),
        (status) {
          emit(BookingStatusUpdated(status));
          if (_shouldStopPolling(status)) {
            stopPolling();
          }
        },
      );
    });
  }

  void startPollingForActive() async {
    _timer?.cancel();
    // First, check for any in-progress booking
    final result = await getMyBookingsUseCase(status: 'InProgress', pageSize: 1);
    result.fold(
      (failure) => emit(BookingStatusError(failure.message)),
      (response) {
        if (response.items.isNotEmpty) {
          final activeBooking = response.items.first;
          emit(BookingActiveFound(activeBooking));
          // Start polling for this specific booking
          startPolling(activeBooking.id);
        } else {
          emit(BookingStatusInitial());
        }
      },
    );
  }

  bool _shouldStopPolling(String status) {
    final s = status.toLowerCase();
    return s == 'completed' || s == 'cancelled' || s == 'expired' || s == 'declined';
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
