import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/helper_booking_entity.dart';
import '../../domain/repositories/helper_bookings_repository.dart';
import '../datasources/helper_bookings_service.dart';

class HelperBookingsRepositoryImpl implements HelperBookingsRepository {
  final HelperBookingsService service;

  HelperBookingsRepositoryImpl(this.service);

  @override
  Future<Either<Failure, List<HelperBookingEntity>>> getRequests() async {
    try {
      final result = await service.getRequests();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> acceptBooking(String bookingId) async {
    try {
      await service.acceptBooking(bookingId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<HelperBookingEntity>>> getUpcomingBookings() async {
    try {
      final result = await service.getUpcomingBookings();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> startTrip(String bookingId) async {
    try {
      await service.startTrip(bookingId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> endTrip(String bookingId) async {
    try {
      await service.endTrip(bookingId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HelperBookingEntity?>> getActiveBooking() async {
    try {
      final result = await service.getActiveBooking();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<HelperBookingEntity>>> getHistory() async {
    try {
      final result = await service.getHistory();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
