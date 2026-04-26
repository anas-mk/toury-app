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

  /// Polls for any booking that is currently active (in progress or accepted).
  /// Uses multiple valid statuses in sequence to find the most relevant one.
  Future<void> startPollingForActive() async {
    if (isClosed) return;
    emit(BookingStatusLoading());

    // Search statuses that indicate an "active" booking requiring user attention
    const activeStatuses = [
      'InProgress',
      'ConfirmedPaid',
      'AcceptedByHelper',
      'PendingHelperResponse',
    ];

    for (final status in activeStatuses) {
      if (isClosed) return;
      final result = await getMyBookingsUseCase(status: status, pageSize: 1);
      final found = result.fold((_) => null, (paged) => paged.items.isNotEmpty ? paged.items.first : null);
      if (found != null) {
        if (!isClosed) {
          emit(BookingStatusActive(found));
          _subscribeToStatusChanges(found.id);
        }
        return;
      }
    }

    if (!isClosed) emit(BookingStatusNoActive());
  }

  void _subscribeToStatusChanges(String bookingId) {
    _statusSubscription?.cancel();
    _statusSubscription = hubService.statusStream.listen((event) {
      final String? eventBookingId = event['bookingId']?.toString();
      if (eventBookingId == bookingId && !isClosed) {
        refreshActiveBooking(bookingId);
      }
    });
  }

  Future<void> refreshActiveBooking(String bookingId) async {
    if (isClosed) return;
    final result = await getBookingDetailsUseCase(bookingId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(BookingStatusError(failure.message)),
      (booking) {
        const terminalStatuses = [
          'completed',
          'cancelledByUser',
          'cancelledByHelper',
          'cancelledBySystem',
          'declinedByHelper',
          'expiredNoResponse',
        ];
        if (terminalStatuses.contains(booking.status.name)) {
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
