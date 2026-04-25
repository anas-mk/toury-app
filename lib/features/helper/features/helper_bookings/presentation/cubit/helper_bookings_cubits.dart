import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../../domain/entities/helper_earnings_entities.dart';
import '../../domain/usecases/helper_bookings_usecases.dart';

// ──────────────────────────────────────────────────────────────────────────────
// HELPER DASHBOARD CUBIT
// ──────────────────────────────────────────────────────────────────────────────

abstract class HelperDashboardState extends Equatable {
  const HelperDashboardState();
  @override List<Object?> get props => [];
}
class HelperDashboardInitial extends HelperDashboardState { const HelperDashboardInitial(); }
class HelperDashboardLoading extends HelperDashboardState { const HelperDashboardLoading(); }
class HelperDashboardLoaded extends HelperDashboardState {
  final HelperDashboard dashboard;
  const HelperDashboardLoaded(this.dashboard);
  @override List<Object?> get props => [dashboard];
}
class HelperDashboardError extends HelperDashboardState {
  final String message;
  const HelperDashboardError(this.message);
  @override List<Object?> get props => [message];
}

class HelperDashboardCubit extends Cubit<HelperDashboardState> {
  final GetHelperDashboardUseCase _getDashboard;
  HelperDashboardCubit(this._getDashboard) : super(const HelperDashboardInitial());

  Future<void> load() async {
    emit(const HelperDashboardLoading());
    try {
      final dashboard = await _getDashboard();
      emit(HelperDashboardLoaded(dashboard));
    } catch (e) {
      emit(HelperDashboardError(e.toString()));
    }
  }

  Future<void> refresh() => load();
}

// ──────────────────────────────────────────────────────────────────────────────
// AVAILABILITY CUBIT
// ──────────────────────────────────────────────────────────────────────────────

abstract class HelperAvailabilityState extends Equatable {
  const HelperAvailabilityState();
  @override List<Object?> get props => [];
}
class AvailabilityInitial extends HelperAvailabilityState { const AvailabilityInitial(); }
class AvailabilityUpdating extends HelperAvailabilityState { const AvailabilityUpdating(); }
class AvailabilityUpdated extends HelperAvailabilityState {
  final AvailabilityStatus status;
  const AvailabilityUpdated(this.status);
  @override List<Object?> get props => [status];
}
class AvailabilityError extends HelperAvailabilityState {
  final String message;
  const AvailabilityError(this.message);
  @override List<Object?> get props => [message];
}

class HelperAvailabilityCubit extends Cubit<HelperAvailabilityState> {
  final UpdateAvailabilityUseCase _updateAvailability;
  HelperAvailabilityCubit(this._updateAvailability) : super(const AvailabilityInitial());

  Future<void> update(AvailabilityStatus status) async {
    emit(const AvailabilityUpdating());
    try {
      await _updateAvailability(status);
      emit(AvailabilityUpdated(status));
    } catch (e) {
      emit(AvailabilityError(e.toString()));
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// INCOMING REQUESTS CUBIT
// ──────────────────────────────────────────────────────────────────────────────

abstract class IncomingRequestsState extends Equatable {
  const IncomingRequestsState();
  @override List<Object?> get props => [];
}
class IncomingRequestsInitial extends IncomingRequestsState { const IncomingRequestsInitial(); }
class IncomingRequestsLoading extends IncomingRequestsState { const IncomingRequestsLoading(); }
class IncomingRequestsLoaded extends IncomingRequestsState {
  final List<HelperBooking> requests;
  const IncomingRequestsLoaded(this.requests);
  @override List<Object?> get props => [requests];
}
class IncomingRequestsError extends IncomingRequestsState {
  final String message;
  const IncomingRequestsError(this.message);
  @override List<Object?> get props => [message];
}

class IncomingRequestsCubit extends Cubit<IncomingRequestsState> {
  final GetIncomingRequestsUseCase _getRequests;
  IncomingRequestsCubit(this._getRequests) : super(const IncomingRequestsInitial());

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(const IncomingRequestsLoading());
    try {
      final requests = await _getRequests();
      emit(IncomingRequestsLoaded(requests));
    } catch (e) {
      emit(IncomingRequestsError(e.toString()));
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// REQUEST DETAILS CUBIT
// ──────────────────────────────────────────────────────────────────────────────

abstract class RequestDetailsState extends Equatable {
  const RequestDetailsState();
  @override List<Object?> get props => [];
}
class RequestDetailsInitial extends RequestDetailsState { const RequestDetailsInitial(); }
class RequestDetailsLoading extends RequestDetailsState { const RequestDetailsLoading(); }
class RequestDetailsLoaded extends RequestDetailsState {
  final HelperBooking booking;
  const RequestDetailsLoaded(this.booking);
  @override List<Object?> get props => [booking];
}
class RequestDetailsError extends RequestDetailsState {
  final String message;
  const RequestDetailsError(this.message);
  @override List<Object?> get props => [message];
}

class RequestDetailsCubit extends Cubit<RequestDetailsState> {
  final GetRequestDetailsUseCase _getDetails;
  RequestDetailsCubit(this._getDetails) : super(const RequestDetailsInitial());

  Future<void> load(String bookingId) async {
    emit(const RequestDetailsLoading());
    try {
      final booking = await _getDetails(bookingId);
      emit(RequestDetailsLoaded(booking));
    } catch (e) {
      emit(RequestDetailsError(e.toString()));
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// ACCEPT BOOKING CUBIT
// ──────────────────────────────────────────────────────────────────────────────

abstract class AcceptBookingState extends Equatable {
  const AcceptBookingState();
  @override List<Object?> get props => [];
}
class AcceptBookingInitial extends AcceptBookingState { const AcceptBookingInitial(); }
class AcceptBookingLoading extends AcceptBookingState { const AcceptBookingLoading(); }
class AcceptBookingSuccess extends AcceptBookingState {
  final HelperBooking booking;
  const AcceptBookingSuccess(this.booking);
  @override List<Object?> get props => [booking];
}
class AcceptBookingError extends AcceptBookingState {
  final String message;
  const AcceptBookingError(this.message);
  @override List<Object?> get props => [message];
}

class AcceptBookingCubit extends Cubit<AcceptBookingState> {
  final AcceptBookingUseCase _acceptBooking;
  AcceptBookingCubit(this._acceptBooking) : super(const AcceptBookingInitial());

  Future<void> accept(String bookingId) async {
    emit(const AcceptBookingLoading());
    try {
      final booking = await _acceptBooking(bookingId);
      emit(AcceptBookingSuccess(booking));
    } catch (e) {
      emit(AcceptBookingError(e.toString()));
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// DECLINE BOOKING CUBIT
// ──────────────────────────────────────────────────────────────────────────────

abstract class DeclineBookingState extends Equatable {
  const DeclineBookingState();
  @override List<Object?> get props => [];
}
class DeclineBookingInitial extends DeclineBookingState { const DeclineBookingInitial(); }
class DeclineBookingLoading extends DeclineBookingState { const DeclineBookingLoading(); }
class DeclineBookingSuccess extends DeclineBookingState { const DeclineBookingSuccess(); }
class DeclineBookingError extends DeclineBookingState {
  final String message;
  const DeclineBookingError(this.message);
  @override List<Object?> get props => [message];
}

class DeclineBookingCubit extends Cubit<DeclineBookingState> {
  final DeclineBookingUseCase _declineBooking;
  DeclineBookingCubit(this._declineBooking) : super(const DeclineBookingInitial());

  Future<void> decline(String bookingId, {String? reason}) async {
    emit(const DeclineBookingLoading());
    try {
      await _declineBooking(bookingId, reason: reason);
      emit(const DeclineBookingSuccess());
    } catch (e) {
      emit(DeclineBookingError(e.toString()));
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// UPCOMING BOOKINGS CUBIT
// ──────────────────────────────────────────────────────────────────────────────

abstract class UpcomingBookingsState extends Equatable {
  const UpcomingBookingsState();
  @override List<Object?> get props => [];
}
class UpcomingBookingsInitial extends UpcomingBookingsState { const UpcomingBookingsInitial(); }
class UpcomingBookingsLoading extends UpcomingBookingsState { const UpcomingBookingsLoading(); }
class UpcomingBookingsLoaded extends UpcomingBookingsState {
  final List<HelperBooking> bookings;
  const UpcomingBookingsLoaded(this.bookings);
  @override List<Object?> get props => [bookings];
}
class UpcomingBookingsError extends UpcomingBookingsState {
  final String message;
  const UpcomingBookingsError(this.message);
  @override List<Object?> get props => [message];
}

class UpcomingBookingsCubit extends Cubit<UpcomingBookingsState> {
  final GetUpcomingBookingsUseCase _getUpcoming;
  UpcomingBookingsCubit(this._getUpcoming) : super(const UpcomingBookingsInitial());

  Future<void> load() async {
    emit(const UpcomingBookingsLoading());
    try {
      final bookings = await _getUpcoming();
      emit(UpcomingBookingsLoaded(bookings));
    } catch (e) {
      emit(UpcomingBookingsError(e.toString()));
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// ACTIVE BOOKING CUBIT
// ──────────────────────────────────────────────────────────────────────────────

abstract class ActiveBookingState extends Equatable {
  const ActiveBookingState();
  @override List<Object?> get props => [];
}
class ActiveBookingInitial extends ActiveBookingState { const ActiveBookingInitial(); }
class ActiveBookingLoading extends ActiveBookingState { const ActiveBookingLoading(); }
class ActiveBookingLoaded extends ActiveBookingState {
  final HelperBooking? booking;
  const ActiveBookingLoaded(this.booking);
  @override List<Object?> get props => [booking];
}
class ActiveBookingError extends ActiveBookingState {
  final String message;
  const ActiveBookingError(this.message);
  @override List<Object?> get props => [message];
}

class ActiveBookingCubit extends Cubit<ActiveBookingState> {
  final GetActiveBookingUseCase _getActive;
  ActiveBookingCubit(this._getActive) : super(const ActiveBookingInitial());

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(const ActiveBookingLoading());
    try {
      final booking = await _getActive();
      emit(ActiveBookingLoaded(booking));
    } catch (e) {
      emit(ActiveBookingError(e.toString()));
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// START TRIP CUBIT
// ──────────────────────────────────────────────────────────────────────────────

abstract class StartTripState extends Equatable {
  const StartTripState();
  @override List<Object?> get props => [];
}
class StartTripInitial extends StartTripState { const StartTripInitial(); }
class StartTripLoading extends StartTripState { const StartTripLoading(); }
class StartTripSuccess extends StartTripState { const StartTripSuccess(); }
class StartTripError extends StartTripState {
  final String message;
  const StartTripError(this.message);
  @override List<Object?> get props => [message];
}

class StartTripCubit extends Cubit<StartTripState> {
  final StartTripUseCase _startTrip;
  StartTripCubit(this._startTrip) : super(const StartTripInitial());

  Future<void> start(String bookingId) async {
    emit(const StartTripLoading());
    try {
      await _startTrip(bookingId);
      emit(const StartTripSuccess());
    } catch (e) {
      emit(StartTripError(e.toString()));
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// END TRIP CUBIT
// ──────────────────────────────────────────────────────────────────────────────

abstract class EndTripState extends Equatable {
  const EndTripState();
  @override List<Object?> get props => [];
}
class EndTripInitial extends EndTripState { const EndTripInitial(); }
class EndTripLoading extends EndTripState { const EndTripLoading(); }
class EndTripSuccess extends EndTripState {
  final double earnings;
  const EndTripSuccess(this.earnings);
  @override List<Object?> get props => [earnings];
}
class EndTripError extends EndTripState {
  final String message;
  const EndTripError(this.message);
  @override List<Object?> get props => [message];
}

class EndTripCubit extends Cubit<EndTripState> {
  final EndTripUseCase _endTrip;
  EndTripCubit(this._endTrip) : super(const EndTripInitial());

  Future<void> end(String bookingId) async {
    emit(const EndTripLoading());
    try {
      final earnings = await _endTrip(bookingId);
      emit(EndTripSuccess(earnings));
    } catch (e) {
      emit(EndTripError(e.toString()));
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// HELPER HISTORY CUBIT
// ──────────────────────────────────────────────────────────────────────────────

abstract class HelperHistoryState extends Equatable {
  const HelperHistoryState();
  @override List<Object?> get props => [];
}
class HelperHistoryInitial extends HelperHistoryState { const HelperHistoryInitial(); }
class HelperHistoryLoading extends HelperHistoryState { const HelperHistoryLoading(); }
class HelperHistoryLoaded extends HelperHistoryState {
  final List<HelperBooking> bookings;
  final bool hasMore;
  const HelperHistoryLoaded(this.bookings, {this.hasMore = false});
  @override List<Object?> get props => [bookings, hasMore];
}
class HelperHistoryError extends HelperHistoryState {
  final String message;
  const HelperHistoryError(this.message);
  @override List<Object?> get props => [message];
}

class HelperHistoryCubit extends Cubit<HelperHistoryState> {
  final GetHelperHistoryUseCase _getHistory;
  int _page = 1;
  static const int _pageSize = 20;
  String? _status;
  DateTime? _from;
  DateTime? _to;

  HelperHistoryCubit(this._getHistory) : super(const HelperHistoryInitial());

  Future<void> load({String? status, DateTime? from, DateTime? to}) async {
    _page = 1;
    _status = status;
    _from = from;
    _to = to;
    emit(const HelperHistoryLoading());
    try {
      final bookings = await _getHistory(status: _status, from: _from, to: _to, page: _page, pageSize: _pageSize);
      emit(HelperHistoryLoaded(bookings, hasMore: bookings.length == _pageSize));
    } catch (e) {
      emit(HelperHistoryError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! HelperHistoryLoaded || !current.hasMore) return;
    _page++;
    try {
      final more = await _getHistory(status: _status, from: _from, to: _to, page: _page, pageSize: _pageSize);
      emit(HelperHistoryLoaded([...current.bookings, ...more], hasMore: more.length == _pageSize));
    } catch (_) {
      _page--;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// EARNINGS CUBIT
// ──────────────────────────────────────────────────────────────────────────────

abstract class EarningsState extends Equatable {
  const EarningsState();
  @override List<Object?> get props => [];
}
class EarningsInitial extends EarningsState { const EarningsInitial(); }
class EarningsLoading extends EarningsState { const EarningsLoading(); }
class EarningsLoaded extends EarningsState {
  final HelperEarnings earnings;
  const EarningsLoaded(this.earnings);
  @override List<Object?> get props => [earnings];
}
class EarningsError extends EarningsState {
  final String message;
  const EarningsError(this.message);
  @override List<Object?> get props => [message];
}

class EarningsCubit extends Cubit<EarningsState> {
  final GetEarningsUseCase _getEarnings;
  EarningsCubit(this._getEarnings) : super(const EarningsInitial());

  Future<void> load() async {
    emit(const EarningsLoading());
    try {
      final earnings = await _getEarnings();
      emit(EarningsLoaded(earnings));
    } catch (e) {
      emit(EarningsError(e.toString()));
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// BOOKING DETAILS CUBIT
// ──────────────────────────────────────────────────────────────────────────────

abstract class HelperBookingDetailsState extends Equatable {
  const HelperBookingDetailsState();
  @override List<Object?> get props => [];
}
class HelperBookingDetailsInitial extends HelperBookingDetailsState { const HelperBookingDetailsInitial(); }
class HelperBookingDetailsLoading extends HelperBookingDetailsState { const HelperBookingDetailsLoading(); }
class HelperBookingDetailsLoaded extends HelperBookingDetailsState {
  final HelperBooking booking;
  const HelperBookingDetailsLoaded(this.booking);
  @override List<Object?> get props => [booking];
}
class HelperBookingDetailsError extends HelperBookingDetailsState {
  final String message;
  const HelperBookingDetailsError(this.message);
  @override List<Object?> get props => [message];
}

class HelperBookingDetailsCubit extends Cubit<HelperBookingDetailsState> {
  final GetHelperBookingDetailsUseCase _getDetails;
  HelperBookingDetailsCubit(this._getDetails) : super(const HelperBookingDetailsInitial());

  Future<void> load(String bookingId) async {
    emit(const HelperBookingDetailsLoading());
    try {
      final booking = await _getDetails(bookingId);
      emit(HelperBookingDetailsLoaded(booking));
    } catch (e) {
      emit(HelperBookingDetailsError(e.toString()));
    }
  }
}
