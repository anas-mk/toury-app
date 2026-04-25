part of 'scheduled_booking_cubit.dart';

abstract class ScheduledBookingState extends Equatable {
  const ScheduledBookingState();

  @override
  List<Object?> get props => [];
}

class ScheduledBookingInitial extends ScheduledBookingState {}

class ScheduledBookingLoading extends ScheduledBookingState {}

class ScheduledBookingSuccess extends ScheduledBookingState {
  final BookingDetailEntity booking;

  const ScheduledBookingSuccess(this.booking);

  @override
  List<Object?> get props => [booking];
}

class ScheduledBookingError extends ScheduledBookingState {
  final String message;

  const ScheduledBookingError(this.message);

  @override
  List<Object?> get props => [message];
}
