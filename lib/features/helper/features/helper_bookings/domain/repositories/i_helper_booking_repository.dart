import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/booking.dart';
import '../entities/booking_status.dart';

abstract class IHelperBookingRepository {
  /// Stream of incoming booking requests
  Stream<Booking> get incomingBookingStream;

  /// Stream of active trip updates
  Stream<Booking> get activeBookingStream;

  /// Gets the currently active booking (useful for crash recovery)
  Future<Either<Failure, Booking?>> getCurrentActiveBooking();

  /// Accepts an incoming request
  Future<Either<Failure, Booking>> acceptBooking(String bookingId);

  /// Rejects an incoming request
  Future<Either<Failure, void>> rejectBooking(String bookingId);

  /// Updates the status of the booking
  Future<Either<Failure, Booking>> updateBookingStatus(String bookingId, BookingStatus status);
}
