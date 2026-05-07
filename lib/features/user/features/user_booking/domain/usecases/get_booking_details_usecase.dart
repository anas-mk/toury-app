import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/booking_detail_entity.dart';
import '../repositories/user_booking_repository.dart';

class GetBookingDetailsUseCase {
  final UserBookingRepository repository;

  GetBookingDetailsUseCase(this.repository);

  Future<Either<Failure, BookingDetailEntity>> call(String bookingId) async {
    return await repository.getBookingDetails(bookingId);
  }
}
