part of 'instant_booking_cubit.dart';

abstract class InstantBookingState extends Equatable {
  const InstantBookingState();

  @override
  List<Object?> get props => [];
}

class InstantBookingInitial extends InstantBookingState {}

class InstantBookingLoading extends InstantBookingState {}

class InstantBookingWaitingResponse extends InstantBookingState {
  final BookingDetailEntity booking;

  const InstantBookingWaitingResponse(this.booking);

  @override
  List<Object?> get props => [booking];
}

class InstantBookingConfirmed extends InstantBookingState {
  final BookingDetailEntity booking;

  const InstantBookingConfirmed(this.booking);

  @override
  List<Object?> get props => [booking];
}

class InstantBookingDeclined extends InstantBookingState {
  final BookingDetailEntity booking;

  const InstantBookingDeclined(this.booking);

  @override
  List<Object?> get props => [booking];
}

class InstantBookingError extends InstantBookingState {
  final String message;

  const InstantBookingError(this.message);

  @override
  List<Object?> get props => [message];
}
