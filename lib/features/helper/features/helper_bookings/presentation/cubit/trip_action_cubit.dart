import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/helper_bookings_usecases.dart';
import '../../domain/entities/helper_booking_entities.dart';

abstract class TripActionState extends Equatable {
  const TripActionState();
  @override
  List<Object?> get props => [];
}

class TripActionInitial extends TripActionState {
  const TripActionInitial();
}

class TripActionLoading extends TripActionState {
  final String actionType; // 'start' or 'end'
  const TripActionLoading(this.actionType);
  @override
  List<Object?> get props => [actionType];
}

// Alias for UI compatibility
typedef TripActionInProgress = TripActionLoading;

class TripActionSuccess extends TripActionState {
  final String actionType;
  final dynamic result; // Could be double (earnings) or null
  final String message;
  
  const TripActionSuccess(this.actionType, {this.result, this.message = ''});
  
  @override
  List<Object?> get props => [actionType, result, message];
}

class TripActionError extends TripActionState {
  final String message;
  const TripActionError(this.message);
  @override
  List<Object?> get props => [message];
}

class TripActionCubit extends Cubit<TripActionState> {
  final StartTripUseCase _startTrip;
  final EndTripUseCase _endTrip;

  TripActionCubit(this._startTrip, this._endTrip) : super(const TripActionInitial());

  Future<void> start(String bookingId) async {
    emit(const TripActionLoading('start'));

    try {
      await _startTrip(bookingId);
      if (isClosed) return;
      emit(const TripActionSuccess('start', message: 'Trip started successfully'));
    } catch (e) {
      if (isClosed) return;
      
      if (e.toString().contains('400') || e.toString().contains('InProgress')) {
        emit(const TripActionSuccess('start', result: 'already_started', message: 'Trip already in progress'));
      } else {
        emit(TripActionError(e.toString()));
      }
    }
  }

  Future<void> end(String bookingId) async {
    emit(const TripActionLoading('end'));

    try {
      final earnings = await _endTrip(bookingId);
      if (isClosed) return;
      emit(TripActionSuccess('end', result: earnings, message: 'Trip ended successfully'));
    } catch (e) {
      if (isClosed) return;
      emit(TripActionError(e.toString()));
    }
  }

  // Keep these for backward compatibility if needed by some pages passing the whole booking
  Future<void> startTrip(HelperBooking booking) => start(booking.id);
  Future<void> endTrip(HelperBooking booking) => end(booking.id);

  void reset() => emit(const TripActionInitial());
}
