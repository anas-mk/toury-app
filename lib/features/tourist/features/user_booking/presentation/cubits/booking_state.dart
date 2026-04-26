import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_detail_entity.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingCreated extends BookingState {
  final BookingDetailEntity booking;

  const BookingCreated(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingCancelled extends BookingState {}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);

  @override
  List<Object?> get props => [message];
}
