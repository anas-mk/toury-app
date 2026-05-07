import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/helper_bookings_usecases.dart';
import '../../domain/entities/helper_booking_entities.dart';

abstract class AcceptRejectRequestState extends Equatable {
  const AcceptRejectRequestState();
  @override
  List<Object?> get props => [];
}

class AcceptRejectRequestInitial extends AcceptRejectRequestState {
  const AcceptRejectRequestInitial();
}

class AcceptLoading extends AcceptRejectRequestState {
  const AcceptLoading();
}

class RejectLoading extends AcceptRejectRequestState {
  const RejectLoading();
}

class AcceptSuccess extends AcceptRejectRequestState {
  final HelperBooking booking;
  const AcceptSuccess(this.booking);
  @override
  List<Object?> get props => [booking];
}

class RejectSuccess extends AcceptRejectRequestState {
  const RejectSuccess();
}

class AcceptRejectFailure extends AcceptRejectRequestState {
  final String message;
  const AcceptRejectFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class AcceptRejectRequestCubit extends Cubit<AcceptRejectRequestState> {
  final AcceptBookingUseCase _acceptBooking;
  final DeclineBookingUseCase _declineBooking;

  AcceptRejectRequestCubit(
    this._acceptBooking,
    this._declineBooking,
  ) : super(const AcceptRejectRequestInitial());

  Future<void> acceptRequest(String bookingId) async {
    emit(const AcceptLoading());
    try {
      final booking = await _acceptBooking(bookingId);
      if (isClosed) return;
      emit(AcceptSuccess(booking));
    } catch (e) {
      if (isClosed) return;
      emit(AcceptRejectFailure(e.toString()));
    }
  }

  Future<void> rejectRequest(String bookingId) async {
    emit(const RejectLoading());
    try {
      await _declineBooking(bookingId);
      if (isClosed) return;
      emit(const RejectSuccess());
    } catch (e) {
      if (isClosed) return;
      emit(AcceptRejectFailure(e.toString()));
    }
  }
}
