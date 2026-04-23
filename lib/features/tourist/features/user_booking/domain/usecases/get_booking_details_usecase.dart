import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/booking_entity.dart';
import '../repositories/user_booking_repository.dart';

class GetBookingDetailsUseCase {
  final UserBookingRepository repository;

  GetBookingDetailsUseCase(this.repository);

  Future<Either<Failure, BookingEntity>> call(String bookingId) {
    return repository.getBookingDetails(bookingId);
  }
}
