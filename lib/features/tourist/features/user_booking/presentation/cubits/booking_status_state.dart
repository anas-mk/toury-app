part of 'booking_status_cubit.dart';

abstract class BookingStatusState extends Equatable {
  const BookingStatusState();

  @override
  List<Object?> get props => [];
}

class BookingStatusInitial extends BookingStatusState {}

class BookingStatusUpdated extends BookingStatusState {
  final String status;

  const BookingStatusUpdated(this.status);

  @override
  List<Object?> get props => [status];
}

class BookingStatusError extends BookingStatusState {
  final String message;

  const BookingStatusError(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingActiveFound extends BookingStatusState {
  final BookingDetailEntity booking;

  const BookingActiveFound(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingAwaitingPayment extends BookingStatusState {
  final BookingDetailEntity booking;

  const BookingAwaitingPayment(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingAwaitingRating extends BookingStatusState {
  final BookingDetailEntity booking;

  const BookingAwaitingRating(this.booking);

  @override
  List<Object?> get props => [booking];
}
