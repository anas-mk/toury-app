import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/usecases/get_my_bookings_usecase.dart';

abstract class MyBookingsState {}
class MyBookingsInitial extends MyBookingsState {}
class MyBookingsLoading extends MyBookingsState {
  final bool isPagination;
  MyBookingsLoading({this.isPagination = false});
}
class MyBookingsSuccess extends MyBookingsState {
  final List<BookingEntity> bookings;
  final bool hasMore;
  MyBookingsSuccess(this.bookings, {this.hasMore = false});
}
class MyBookingsError extends MyBookingsState {
  final String message;
  MyBookingsError(this.message);
}

class MyBookingsCubit extends Cubit<MyBookingsState> {
  final GetMyBookingsUseCase getMyBookings;
  
  int _currentPage = 1;
  final int _pageSize = 10;
  List<BookingEntity> _currentBookings = [];
  bool _hasMore = true;
  String? _currentStatus;

  MyBookingsCubit({required this.getMyBookings}) : super(MyBookingsInitial());

  Future<void> loadBookings({String? status, bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _currentBookings = [];
      _hasMore = true;
    }
    
    if (!_hasMore) return;
    
    _currentStatus = status;
    emit(MyBookingsLoading(isPagination: !isRefresh && _currentBookings.isNotEmpty));

    final result = await getMyBookings(GetMyBookingsParams(
      status: _currentStatus,
      page: _currentPage,
      pageSize: _pageSize,
    ));

    result.fold(
      (failure) => emit(MyBookingsError(failure.message)),
      (response) {
        _currentBookings.addAll(response.items);
        _hasMore = response.items.length == _pageSize;
        _currentPage++;
        emit(MyBookingsSuccess(List.from(_currentBookings), hasMore: _hasMore));
      },
    );
  }
}
