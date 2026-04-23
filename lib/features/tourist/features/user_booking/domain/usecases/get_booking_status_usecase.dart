import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/booking_status_entity.dart';
import '../repositories/user_booking_repository.dart';

class GetBookingStatusUseCase {
  final UserBookingRepository repository;

  GetBookingStatusUseCase(this.repository);

  Future<Either<Failure, BookingStatusEntity>> call(String bookingId) {
    return repository.getBookingStatus(bookingId);
  }
}
