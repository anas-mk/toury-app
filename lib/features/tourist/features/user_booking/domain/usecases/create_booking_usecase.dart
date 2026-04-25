import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/booking_detail_entity.dart';
import '../repositories/user_booking_repository.dart';

class CreateScheduledBookingUseCase {
  final UserBookingRepository repository;

  CreateScheduledBookingUseCase(this.repository);

  Future<Either<Failure, BookingDetailEntity>> call(Map<String, dynamic> bookingData) async {
    return await repository.createScheduledBooking(bookingData);
  }
}

class CreateInstantBookingUseCase {
  final UserBookingRepository repository;

  CreateInstantBookingUseCase(this.repository);

  Future<Either<Failure, BookingDetailEntity>> call(Map<String, dynamic> bookingData) async {
    return await repository.createInstantBooking(bookingData);
  }
}
