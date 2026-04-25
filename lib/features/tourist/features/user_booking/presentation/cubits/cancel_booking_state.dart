part of 'cancel_booking_cubit.dart';

abstract class CancelBookingState extends Equatable {
  const CancelBookingState();

  @override
  List<Object?> get props => [];
}

class CancelBookingInitial extends CancelBookingState {}

class CancelBookingLoading extends CancelBookingState {}

class CancelBookingSuccess extends CancelBookingState {}

class CancelBookingError extends CancelBookingState {
  final String message;

  const CancelBookingError(this.message);

  @override
  List<Object?> get props => [message];
}
