import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/helper_bookings_usecases.dart';
import 'helper_bookings_state.dart';

class HelperBookingsCubit extends Cubit<HelperBookingsState> {
  final GetRequestsUseCase getRequestsUseCase;
  final AcceptBookingUseCase acceptBookingUseCase;
  final GetUpcomingBookingsUseCase getUpcomingBookingsUseCase;
  final StartTripUseCase startTripUseCase;
  final EndTripUseCase endTripUseCase;
  final GetActiveBookingUseCase getActiveBookingUseCase;
  final GetHistoryUseCase getHistoryUseCase;

  HelperBookingsCubit({
    required this.getRequestsUseCase,
    required this.acceptBookingUseCase,
    required this.getUpcomingBookingsUseCase,
    required this.startTripUseCase,
    required this.endTripUseCase,
    required this.getActiveBookingUseCase,
    required this.getHistoryUseCase,
  }) : super(const HelperBookingsState());

  Future<void> loadAllBookings() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    final results = await Future.wait([
      getRequestsUseCase(),
      getUpcomingBookingsUseCase(),
      getActiveBookingUseCase(),
      getHistoryUseCase(),
    ]);

    final requestsResult = results[0];
    final upcomingResult = results[1];
    final activeResult = results[2];
    final historyResult = results[3];

    emit(state.copyWith(
      isLoading: false,
      requests: requestsResult.fold((f) => [], (r) => r as dynamic),
      upcoming: upcomingResult.fold((f) => [], (r) => r as dynamic),
      active: activeResult.fold((f) => null, (r) => r as dynamic),
      history: historyResult.fold((f) => [], (r) => r as dynamic),
    ));
  }

  Future<void> fetchRequests() async {
    emit(state.copyWith(isLoading: true));
    final result = await getRequestsUseCase();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (requests) => emit(state.copyWith(isLoading: false, requests: requests)),
    );
  }

  Future<void> fetchUpcoming() async {
    emit(state.copyWith(isLoading: true));
    final result = await getUpcomingBookingsUseCase();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (upcoming) => emit(state.copyWith(isLoading: false, upcoming: upcoming)),
    );
  }

  Future<void> fetchActive() async {
    emit(state.copyWith(isLoading: true));
    final result = await getActiveBookingUseCase();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (active) => emit(state.copyWith(isLoading: false, active: active)),
    );
  }

  Future<void> fetchHistory() async {
    emit(state.copyWith(isLoading: true));
    final result = await getHistoryUseCase();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (history) => emit(state.copyWith(isLoading: false, history: history)),
    );
  }

  Future<void> acceptBooking(String bookingId) async {
    emit(state.copyWith(actionLoadingId: bookingId));
    final result = await acceptBookingUseCase(bookingId);
    result.fold(
      (failure) => emit(state.copyWith(actionLoadingId: null, errorMessage: failure.message)),
      (_) async {
        await loadAllBookings();
      },
    );
  }

  Future<void> startTrip(String bookingId) async {
    emit(state.copyWith(actionLoadingId: bookingId));
    final result = await startTripUseCase(bookingId);
    result.fold(
      (failure) => emit(state.copyWith(actionLoadingId: null, errorMessage: failure.message)),
      (_) async {
        await loadAllBookings();
      },
    );
  }

  Future<void> endTrip(String bookingId) async {
    emit(state.copyWith(actionLoadingId: bookingId));
    final result = await endTripUseCase(bookingId);
    result.fold(
      (failure) => emit(state.copyWith(actionLoadingId: null, errorMessage: failure.message)),
      (_) async {
        await loadAllBookings();
      },
    );
  }
}
