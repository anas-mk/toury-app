import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../../domain/entities/helper_earnings_entities.dart';
import '../../domain/usecases/helper_bookings_usecases.dart';
import 'dart:async';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';

// HELPER HISTORY CUBIT
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
      if (isClosed) return;
      emit(HelperHistoryLoaded(bookings, hasMore: bookings.length == _pageSize));
    } catch (e) {
      if (isClosed) return;
      emit(HelperHistoryError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! HelperHistoryLoaded || !current.hasMore) return;
    _page++;
    try {
      final more = await _getHistory(status: _status, from: _from, to: _to, page: _page, pageSize: _pageSize);
      if (isClosed) return;
      emit(HelperHistoryLoaded([...current.bookings, ...more], hasMore: more.length == _pageSize));
    } catch (_) {
      if (isClosed) return;
      _page--;
    }
  }
}

