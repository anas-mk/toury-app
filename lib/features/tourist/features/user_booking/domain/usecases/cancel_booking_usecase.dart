import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/user_booking_repository.dart';

class CancelBookingParams {
  final String bookingId;
  final String reason;

  const CancelBookingParams({
    required this.bookingId,
    required this.reason,
  });
}

class CancelBookingUseCase {
  final UserBookingRepository repository;

  CancelBookingUseCase(this.repository);

  Future<Either<Failure, void>> call(CancelBookingParams params) {
    return repository.cancelBooking(params.bookingId, params.reason);
  }
}
