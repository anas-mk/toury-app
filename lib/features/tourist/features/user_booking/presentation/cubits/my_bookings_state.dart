import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../../data/models/paged_response_model.dart';

abstract class MyBookingsState extends Equatable {
  const MyBookingsState();

  @override
  List<Object?> get props => [];
}

class MyBookingsInitial extends MyBookingsState {}

class MyBookingsLoading extends MyBookingsState {}

class MyBookingsLoaded extends MyBookingsState {
  final List<BookingDetailEntity> bookings;
  final bool hasReachedMax;
  final int currentPage;

  const MyBookingsLoaded({
    required this.bookings,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [bookings, hasReachedMax, currentPage];

  MyBookingsLoaded copyWith({
    List<BookingDetailEntity>? bookings,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return MyBookingsLoaded(
      bookings: bookings ?? this.bookings,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class MyBookingsError extends MyBookingsState {
  final String message;

  const MyBookingsError(this.message);

  @override
  List<Object?> get props => [message];
}
