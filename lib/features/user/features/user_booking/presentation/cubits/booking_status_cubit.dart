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

  // Reentrancy guard. The home page can mount more than once during a
  // session (tab switch, hot reload, deep-link). Without this guard
  // we end up firing the same /api/user/bookings call multiple times
  // in parallel, which both wastes battery and amplifies any
  // server-side 500 into a flood of error logs.
  bool _inFlight = false;

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
    if (_inFlight) return;
    _inFlight = true;

    // Only show the loading shimmer on the very first call. Subsequent
    // refreshes keep the existing card visible so the UI never blanks
    // out under the user's finger.
    if (state is BookingStatusInitial) {
      emit(BookingStatusLoading());
    }

    try {
      final result = await getMyBookingsUseCase(pageSize: 10);
      result.fold(
        (failure) {
          // Network/500 is not fatal here — the active-trip banner is
          // optional UI. Fall back to "no active" so the home page is
          // fully interactive instead of stuck on a loading skeleton.
          if (state is! BookingStatusActive) {
            emit(BookingStatusNoActive());
          }
        },
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
    } finally {
      _inFlight = false;
    }
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
