import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/helper_booking_entity.dart';
import '../repositories/helper_bookings_repository.dart';

class GetRequestsUseCase {
  final HelperBookingsRepository repository;
  GetRequestsUseCase(this.repository);
  Future<Either<Failure, List<HelperBookingEntity>>> call() => repository.getRequests();
}

class AcceptBookingUseCase {
  final HelperBookingsRepository repository;
  AcceptBookingUseCase(this.repository);
  Future<Either<Failure, Unit>> call(String bookingId) => repository.acceptBooking(bookingId);
}

class GetUpcomingBookingsUseCase {
  final HelperBookingsRepository repository;
  GetUpcomingBookingsUseCase(this.repository);
  Future<Either<Failure, List<HelperBookingEntity>>> call() => repository.getUpcomingBookings();
}

class StartTripUseCase {
  final HelperBookingsRepository repository;
  StartTripUseCase(this.repository);
  Future<Either<Failure, Unit>> call(String bookingId) => repository.startTrip(bookingId);
}

class EndTripUseCase {
  final HelperBookingsRepository repository;
  EndTripUseCase(this.repository);
  Future<Either<Failure, Unit>> call(String bookingId) => repository.endTrip(bookingId);
}

class GetActiveBookingUseCase {
  final HelperBookingsRepository repository;
  GetActiveBookingUseCase(this.repository);
  Future<Either<Failure, HelperBookingEntity?>> call() => repository.getActiveBooking();
}

class GetHistoryUseCase {
  final HelperBookingsRepository repository;
  GetHistoryUseCase(this.repository);
  Future<Either<Failure, List<HelperBookingEntity>>> call() => repository.getHistory();
}
