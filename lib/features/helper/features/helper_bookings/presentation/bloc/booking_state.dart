import 'package:equatable/equatable.dart';
import '../../domain/entities/booking.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingIdle extends BookingState {}

class BookingSearching extends BookingState {}

class BookingIncomingRequest extends BookingState {
  final Booking booking;
  const BookingIncomingRequest(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingAccepted extends BookingState {
  final Booking booking;
  const BookingAccepted(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingNavigatingToPickup extends BookingState {
  final Booking booking;
  const BookingNavigatingToPickup(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingArrived extends BookingState {
  final Booking booking;
  const BookingArrived(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingTripStarted extends BookingState {
  final Booking booking;
  const BookingTripStarted(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingTripInProgress extends BookingState {
  final Booking booking;
  const BookingTripInProgress(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingTripEnding extends BookingState {
  final Booking booking;
  const BookingTripEnding(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingCompleted extends BookingState {
  final Booking booking;
  const BookingCompleted(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingCancelled extends BookingState {
  final Booking? booking;
  final String reason;

  const BookingCancelled(this.reason, {this.booking});

  @override
  List<Object?> get props => [reason, booking];
}
