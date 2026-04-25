part of 'booking_details_cubit.dart';

abstract class BookingDetailsState extends Equatable {
  const BookingDetailsState();

  @override
  List<Object?> get props => [];
}

class BookingDetailsInitial extends BookingDetailsState {}

class BookingDetailsLoading extends BookingDetailsState {}

class BookingDetailsLoaded extends BookingDetailsState {
  final BookingDetailEntity booking;

  const BookingDetailsLoaded(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingDetailsError extends BookingDetailsState {
  final String message;

  const BookingDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

class HelperProfileLoading extends BookingDetailsState {}

class HelperProfileLoaded extends BookingDetailsState {
  final HelperBookingEntity helper;

  const HelperProfileLoaded(this.helper);

  @override
  List<Object?> get props => [helper];
}

class HelperProfileError extends BookingDetailsState {
  final String message;

  const HelperProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
