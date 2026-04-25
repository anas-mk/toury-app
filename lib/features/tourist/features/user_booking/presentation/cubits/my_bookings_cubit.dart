import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../../domain/usecases/get_my_bookings_usecase.dart';

part 'my_bookings_state.dart';

class MyBookingsCubit extends Cubit<MyBookingsState> {
  final GetMyBookingsUseCase getMyBookingsUseCase;
  int _currentPage = 1;
  bool _isFetching = false;

  MyBookingsCubit({
    required this.getMyBookingsUseCase,
  }) : super(MyBookingsInitial());

  Future<void> getBookings({String? status, bool refresh = false, int pageSize = 10}) async {
    if (_isFetching) return;
    if (refresh) {
      _currentPage = 1;
      emit(MyBookingsLoading());
    } else if (state is MyBookingsLoaded) {
      if (!(state as MyBookingsLoaded).hasNextPage) return;
      _currentPage++;
    } else {
      emit(MyBookingsLoading());
    }

    _isFetching = true;
    final result = await getMyBookingsUseCase(page: _currentPage, pageSize: pageSize, status: status);
    _isFetching = false;

    result.fold(
      (failure) => emit(MyBookingsError(failure.message)),
      (pagedResponse) {
        final List<BookingDetailEntity> currentItems = refresh ? [] : (state is MyBookingsLoaded ? (state as MyBookingsLoaded).bookings : []);
        emit(MyBookingsLoaded(
          bookings: [...currentItems, ...pagedResponse.items],
          hasNextPage: pagedResponse.hasNextPage,
          status: status,
        ));
      },
    );
  }
}
