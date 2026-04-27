import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_my_bookings_usecase.dart';
import 'my_bookings_state.dart';

class MyBookingsCubit extends Cubit<MyBookingsState> {
  final GetMyBookingsUseCase getMyBookingsUseCase;

  // Reentrancy guard. Without it, a second tap (or a duplicate
  // mount) fires another network call before the first one returns,
  // which is what produced the duplicate `pageSize=5` 500s in the
  // logs.
  bool _inFlight = false;

  MyBookingsCubit({required this.getMyBookingsUseCase}) : super(MyBookingsInitial());

  Future<void> getBookings({int pageSize = 10, String? status, bool refresh = false}) async {
    if (_inFlight) return;
    if (state is MyBookingsLoading && !refresh) return;

    final currentState = state;
    int pageToFetch = 1;

    if (currentState is MyBookingsLoaded && !refresh) {
      if (currentState.hasReachedMax) return;
      pageToFetch = currentState.currentPage + 1;
    } else if (currentState is! MyBookingsLoaded) {
      // Only show the full-page loading state when we have nothing
      // to render yet. On refresh-with-data, keep the existing list
      // visible to avoid a flicker.
      emit(MyBookingsLoading());
    }

    _inFlight = true;
    try {
      final result = await getMyBookingsUseCase(
        page: pageToFetch,
        pageSize: pageSize,
        status: status,
      );

      result.fold(
        (failure) {
          // CRITICAL: if we already had data on screen, keep it.
          // Showing a full-screen error when the user merely pulled
          // to refresh is what made the UI feel "frozen".
          if (currentState is MyBookingsLoaded) {
            emit(currentState);
          } else {
            // No prior data — degrade gracefully to an empty list
            // so the home page can show its empty state instead of
            // a blocking error screen.
            emit(const MyBookingsLoaded(
              bookings: [],
              hasReachedMax: true,
              currentPage: 1,
            ));
          }
        },
        (pagedResponse) {
          if (pageToFetch == 1) {
            emit(MyBookingsLoaded(
              bookings: pagedResponse.items,
              hasReachedMax: !pagedResponse.hasNextPage,
              currentPage: pagedResponse.pageNumber,
            ));
          } else if (currentState is MyBookingsLoaded) {
            emit(MyBookingsLoaded(
              bookings: currentState.bookings + pagedResponse.items,
              hasReachedMax: !pagedResponse.hasNextPage,
              currentPage: pagedResponse.pageNumber,
            ));
          }
        },
      );
    } finally {
      _inFlight = false;
    }
  }

  Future<void> refreshBookings({int pageSize = 10, String? status}) async {
    await getBookings(pageSize: pageSize, status: status, refresh: true);
  }
}
