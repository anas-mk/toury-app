part of 'my_bookings_cubit.dart';

abstract class MyBookingsState extends Equatable {
  const MyBookingsState();

  @override
  List<Object?> get props => [];
}

class MyBookingsInitial extends MyBookingsState {}

class MyBookingsLoading extends MyBookingsState {}

class MyBookingsLoaded extends MyBookingsState {
  final List<BookingDetailEntity> bookings;
  final bool hasNextPage;
  final String? status;

  const MyBookingsLoaded({
    required this.bookings,
    required this.hasNextPage,
    this.status,
  });

  @override
  List<Object?> get props => [bookings, hasNextPage, status];
}

class MyBookingsError extends MyBookingsState {
  final String message;

  const MyBookingsError(this.message);

  @override
  List<Object?> get props => [message];
}
