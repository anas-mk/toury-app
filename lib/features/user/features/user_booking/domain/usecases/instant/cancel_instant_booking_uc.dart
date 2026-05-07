import 'package:dartz/dartz.dart';

import '../../../../../../../core/errors/failures.dart';
import '../../entities/booking_detail.dart';
import '../../repositories/instant_booking_repository.dart';

class CancelInstantBookingUC {
  final InstantBookingRepository repository;
  const CancelInstantBookingUC(this.repository);

  Future<Either<Failure, BookingDetail>> call({
    required String bookingId,
    required String reason,
  }) =>
      repository.cancelBooking(bookingId, reason);
}
