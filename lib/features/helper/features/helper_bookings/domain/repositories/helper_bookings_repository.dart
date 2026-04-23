import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/helper_booking_entity.dart';

abstract class HelperBookingsRepository {
  Future<Either<Failure, List<HelperBookingEntity>>> getRequests();
  Future<Either<Failure, Unit>> acceptBooking(String bookingId);
  Future<Either<Failure, List<HelperBookingEntity>>> getUpcomingBookings();
  Future<Either<Failure, Unit>> startTrip(String bookingId);
  Future<Either<Failure, Unit>> endTrip(String bookingId);
  Future<Either<Failure, HelperBookingEntity?>> getActiveBooking();
  Future<Either<Failure, List<HelperBookingEntity>>> getHistory();
}
