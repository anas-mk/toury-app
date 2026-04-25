import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/helper_booking_entity.dart';
import '../repositories/user_booking_repository.dart';

class CancelBookingUseCase {
  final UserBookingRepository repository;

  CancelBookingUseCase(this.repository);

  Future<Either<Failure, void>> call(String bookingId, String reason) async {
    return await repository.cancelBooking(bookingId, reason);
  }
}

class GetAlternativesUseCase {
  final UserBookingRepository repository;

  GetAlternativesUseCase(this.repository);

  Future<Either<Failure, List<HelperBookingEntity>>> call(String bookingId) async {
    return await repository.getAlternatives(bookingId);
  }
}

class GetBookingStatusUseCase {
  final UserBookingRepository repository;

  GetBookingStatusUseCase(this.repository);

  Future<Either<Failure, String>> call(String bookingId) async {
    return await repository.getBookingStatus(bookingId);
  }
}
