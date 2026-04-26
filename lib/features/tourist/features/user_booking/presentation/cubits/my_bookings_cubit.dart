import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_my_bookings_usecase.dart';
import 'my_bookings_state.dart';

class MyBookingsCubit extends Cubit<MyBookingsState> {
  final GetMyBookingsUseCase getMyBookingsUseCase;

  MyBookingsCubit({required this.getMyBookingsUseCase}) : super(MyBookingsInitial());

  Future<void> getBookings({int pageSize = 10, String? status, bool refresh = false}) async {
    if (state is MyBookingsLoading && !refresh) return;

    final currentState = state;
    int pageToFetch = 1;

    if (currentState is MyBookingsLoaded && !refresh) {
      if (currentState.hasReachedMax) return;
      pageToFetch = currentState.currentPage + 1;
    } else {
      emit(MyBookingsLoading());
    }

    final result = await getMyBookingsUseCase(
      page: pageToFetch,
      pageSize: pageSize,
      status: status,
    );

    result.fold(
      (failure) => emit(MyBookingsError(failure.message)),
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
  }

  Future<void> refreshBookings({int pageSize = 10, String? status}) async {
    await getBookings(pageSize: pageSize, status: status, refresh: true);
  }
}
