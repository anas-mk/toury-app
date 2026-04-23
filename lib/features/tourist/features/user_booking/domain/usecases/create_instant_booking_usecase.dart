import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/booking_entity.dart';
import '../repositories/user_booking_repository.dart';

class CreateInstantBookingUseCase {
  final UserBookingRepository repository;

  CreateInstantBookingUseCase(this.repository);

  // In a real app, this would probably take a params object with booking details
  Future<Either<Failure, BookingEntity>> call() {
    return repository.createInstantBooking();
  }
}
