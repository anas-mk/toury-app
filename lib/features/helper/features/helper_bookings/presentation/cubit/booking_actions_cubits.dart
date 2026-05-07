import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../../domain/entities/helper_availability_state.dart';
import '../../domain/entities/helper_earnings_entities.dart';
import '../../domain/usecases/helper_bookings_usecases.dart';
import 'dart:async';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';

// ACCEPT BOOKING CUBIT
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
      if (isClosed) return;
      emit(AcceptBookingSuccess(booking));
    } catch (e) {
      if (isClosed) return;
      emit(AcceptBookingError(e.toString()));
    }
  }
}

// DECLINE BOOKING CUBIT
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
      if (isClosed) return;
      emit(const DeclineBookingSuccess());
    } catch (e) {
      if (isClosed) return;
      emit(DeclineBookingError(e.toString()));
    }
  }
}



