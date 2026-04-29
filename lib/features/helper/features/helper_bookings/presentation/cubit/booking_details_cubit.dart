import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../../domain/entities/helper_earnings_entities.dart';
import '../../domain/usecases/helper_bookings_usecases.dart';
import 'dart:async';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';

// BOOKING DETAILS CUBIT
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
      if (isClosed) return;
      emit(HelperBookingDetailsLoaded(booking));
    } catch (e) {
      if (isClosed) return;
      emit(HelperBookingDetailsError(e.toString()));
    }
  }
}

