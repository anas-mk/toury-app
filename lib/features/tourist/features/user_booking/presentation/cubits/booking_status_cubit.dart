import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../../../../../core/widgets/booking_status_chip.dart';
import '../../domain/entities/booking_detail_entity.dart';
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

  /// Look for the most recent active booking and surface it on the home
  /// screen as the "Your active trip" banner.
  ///
  /// IMPORTANT: the previous version of this code sent `?status=Active`
  /// to the backend, but the API only accepts the concrete BookingStatus
  /// values (`PendingHelperResponse`, `AcceptedByHelper`, ...). The server
  /// responded with 400. We now fetch a small page of recent bookings and
  /// filter client-side using [BookingStatusChip.isActive], which keeps the
  /// definition of "active" in one place.
  Future<void> startPollingForActive() async {
    emit(BookingStatusLoading());
    final result = await getMyBookingsUseCase(pageSize: 10);
    result.fold(
      (failure) => emit(BookingStatusError(failure.message)),
      (pagedResponse) {
        final activeList = pagedResponse.items
            .where((b) => BookingStatusChip.isActive(b.status))
            .toList()
          ..sort(
            (a, b) {
              final ar = _activeRank(a.status);
              final br = _activeRank(b.status);
              if (ar != br) return ar.compareTo(br);
              return b.requestedDate.compareTo(a.requestedDate);
            },
          );
        if (activeList.isNotEmpty) {
          final activeBooking = activeList.first;
          emit(BookingStatusActive(activeBooking));
          _subscribeToStatusChanges(activeBooking.id);
        } else {
          emit(BookingStatusNoActive());
        }
      },
    );
  }

  /// Lower rank wins: in-progress trips beat upcoming trips beat pending.
  static int _activeRank(BookingStatus s) {
    switch (s) {
      case BookingStatus.inProgress:
        return 0;
      case BookingStatus.acceptedByHelper:
      case BookingStatus.confirmedPaid:
        return 1;
      case BookingStatus.confirmedAwaitingPayment:
        return 2;
      case BookingStatus.upcoming:
        return 3;
      case BookingStatus.pendingHelperResponse:
      case BookingStatus.reassignmentInProgress:
      case BookingStatus.waitingForUserAction:
        return 4;
      default:
        return 99;
    }
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
