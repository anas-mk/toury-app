import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/booking_actions_usecase.dart';
import '../../domain/usecases/get_my_bookings_usecase.dart';
import '../../domain/usecases/get_booking_details_usecase.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';

part 'booking_status_state.dart';

class BookingStatusCubit extends Cubit<BookingStatusState> {
  final GetBookingStatusUseCase getBookingStatusUseCase;
  final GetMyBookingsUseCase getMyBookingsUseCase;
  final GetBookingDetailsUseCase getBookingDetailsUseCase;
  final BookingTrackingHubService hubService;
  
  Timer? _timer;
  StreamSubscription? _hubSubscription;
  String? _activeBookingId;

  BookingStatusCubit({
    required this.getBookingStatusUseCase,
    required this.getMyBookingsUseCase,
    required this.getBookingDetailsUseCase,
    required this.hubService,
  }) : super(BookingStatusInitial()) {
    _setupHubListener();
  }

  void _setupHubListener() {
    _hubSubscription?.cancel();
    _hubSubscription = hubService.statusStream.listen((event) {
      final String? bId = event['bookingId'];
      final String? newStatus = event['newStatus'];
      
      // If the event is for the booking we are currently tracking, or if we aren't tracking any (and it might be a new relevant one)
      if (bId != null && (bId == _activeBookingId || _activeBookingId == null)) {
        if (newStatus != null) {
          _refreshActiveBooking(bId);
        }
      }
    });
  }

  Future<void> _refreshActiveBooking(String bookingId) async {
    final result = await getBookingDetailsUseCase(bookingId);
    result.fold(
      (failure) => emit(BookingStatusError(failure.message)),
      (booking) {
        _activeBookingId = booking.id;
        _emitStateForStatus(booking);
      },
    );
  }

  void _emitStateForStatus(BookingDetailEntity booking) {
    final status = booking.status;

    if (status == BookingStatus.inProgress || status == BookingStatus.acceptedByHelper || status == BookingStatus.confirmedPaid) {
      emit(BookingActiveFound(booking));
    } else if (status == BookingStatus.confirmedAwaitingPayment) {
      emit(BookingAwaitingPayment(booking));
    } else if (status == BookingStatus.completed) {
      emit(BookingAwaitingRating(booking));
    } else if (_isTerminalStatus(status)) {
      _activeBookingId = null;
      emit(BookingStatusInitial());
      stopPolling();
    } else {
      emit(BookingStatusUpdated(status.name));
    }
  }

  bool _isTerminalStatus(BookingStatus status) {
    return const [
      BookingStatus.completed,
      BookingStatus.cancelledByUser,
      BookingStatus.cancelledByHelper,
      BookingStatus.cancelledBySystem,
      BookingStatus.expired,
      BookingStatus.declined,
    ].contains(status);
  }

  void startPolling(String bookingId) {
    _activeBookingId = bookingId;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final result = await getBookingDetailsUseCase(bookingId);
      result.fold(
        (failure) => null, // Keep current state on poll error
        (booking) => _emitStateForStatus(booking),
      );
    });
  }

  void startPollingForActive() async {
    _timer?.cancel();
    // 1. Check for InProgress
    final inProgress = await getMyBookingsUseCase(status: 'InProgress', pageSize: 1);
    inProgress.fold(
      (failure) => emit(BookingStatusError(failure.message)),
      (response) {
        if (response.items.isNotEmpty) {
          final booking = response.items.first;
          _activeBookingId = booking.id;
          emit(BookingActiveFound(booking));
          startPolling(booking.id);
        } else {
          _checkForAcceptedByHelper();
        }
      },
    );
  }

  void _checkForAcceptedByHelper() async {
    final result = await getMyBookingsUseCase(status: 'AcceptedByHelper', pageSize: 1);
    result.fold(
      (failure) => _checkForConfirmedPaid(),
      (response) {
        if (response.items.isNotEmpty) {
          final booking = response.items.first;
          _activeBookingId = booking.id;
          emit(BookingActiveFound(booking));
          startPolling(booking.id);
        } else {
          _checkForConfirmedPaid();
        }
      },
    );
  }

  void _checkForConfirmedPaid() async {
    final result = await getMyBookingsUseCase(status: 'ConfirmedPaid', pageSize: 1);
    result.fold(
      (failure) => _checkForAwaitingPayment(),
      (response) {
        if (response.items.isNotEmpty) {
          final booking = response.items.first;
          _activeBookingId = booking.id;
          emit(BookingActiveFound(booking));
          startPolling(booking.id);
        } else {
          _checkForAwaitingPayment();
        }
      },
    );
  }

  void _checkForAwaitingPayment() async {
    final result = await getMyBookingsUseCase(status: 'ConfirmedAwaitingPayment', pageSize: 1);
    result.fold(
      (failure) => emit(BookingStatusInitial()),
      (response) {
        if (response.items.isNotEmpty) {
          final booking = response.items.first;
          _activeBookingId = booking.id;
          emit(BookingAwaitingPayment(booking));
          startPolling(booking.id);
        } else {
          _checkForAwaitingRating();
        }
      },
    );
  }

  void _checkForAwaitingRating() async {
    final result = await getMyBookingsUseCase(status: 'Completed', pageSize: 1);
    result.fold(
      (failure) => emit(BookingStatusInitial()),
      (response) {
        if (response.items.isNotEmpty) {
          final booking = response.items.first;
          // Note: Ideally check if already rated here via a usecase
          emit(BookingAwaitingRating(booking));
        } else {
          emit(BookingStatusInitial());
        }
      },
    );
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _activeBookingId = null;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _hubSubscription?.cancel();
    return super.close();
  }
}
