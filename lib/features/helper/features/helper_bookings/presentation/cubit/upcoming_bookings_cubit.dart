import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../../domain/entities/helper_earnings_entities.dart';
import '../../domain/usecases/helper_bookings_usecases.dart';
import 'dart:async';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';

// UPCOMING BOOKINGS CUBIT
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
      if (isClosed) return;
      debugPrint('✅ [UpcomingBookingsCubit] Loaded ${bookings.length} bookings');
      emit(UpcomingBookingsLoaded(bookings));
    } catch (e) {
      if (isClosed) return;
      debugPrint('❌ [UpcomingBookingsCubit] Error: $e');
      emit(UpcomingBookingsError(e.toString()));
    }
  }
}

