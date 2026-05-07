import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_detail_entity.dart';

abstract class BookingStatusState extends Equatable {
  const BookingStatusState();

  @override
  List<Object?> get props => [];
}

class BookingStatusInitial extends BookingStatusState {}

class BookingStatusLoading extends BookingStatusState {}

class BookingStatusActive extends BookingStatusState {
  final BookingDetailEntity booking;

  const BookingStatusActive(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingStatusNoActive extends BookingStatusState {}

class BookingStatusError extends BookingStatusState {
  final String message;

  const BookingStatusError(this.message);

  @override
  List<Object?> get props => [message];
}
