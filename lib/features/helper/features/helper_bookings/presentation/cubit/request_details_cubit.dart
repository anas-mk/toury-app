import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../../domain/usecases/helper_bookings_usecases.dart';
import 'dart:async';

// REQUEST DETAILS CUBIT
abstract class RequestDetailsState extends Equatable {
  const RequestDetailsState();
  @override List<Object?> get props => [];
}
class RequestDetailsInitial extends RequestDetailsState { const RequestDetailsInitial(); }
class RequestDetailsLoading extends RequestDetailsState { const RequestDetailsLoading(); }
class RequestDetailsLoaded extends RequestDetailsState {
  final HelperBooking booking;
  const RequestDetailsLoaded(this.booking);
  @override List<Object?> get props => [booking];
}
class RequestDetailsError extends RequestDetailsState {
  final String message;
  const RequestDetailsError(this.message);
  @override List<Object?> get props => [message];
}

class RequestDetailsCubit extends Cubit<RequestDetailsState> {
  final GetRequestDetailsUseCase _getDetails;
  RequestDetailsCubit(this._getDetails) : super(const RequestDetailsInitial());

  Future<void> load(String bookingId) async {
    emit(const RequestDetailsLoading());
    try {
      final booking = await _getDetails(bookingId);
      if (isClosed) return;
      emit(RequestDetailsLoaded(booking));
    } catch (e) {
      if (isClosed) return;
      emit(RequestDetailsError(e.toString()));
    }
  }

  void optimisticUpdateStatus(String newStatus) {
    if (state is RequestDetailsLoaded) {
      final current = (state as RequestDetailsLoaded).booking;
      emit(RequestDetailsLoaded(current.copyWith(status: newStatus)));
    }
  }

  /// Replace the loaded booking with a server-confirmed entity (e.g. the
  /// updated booking returned by the accept-request API). This is preferred
  /// over [optimisticUpdateStatus] when we already have the new entity, since
  /// it also refreshes flags like `canStartTrip` / `canEndTrip`.
  void setBooking(HelperBooking booking) {
    if (isClosed) return;
    emit(RequestDetailsLoaded(booking));
  }
}


