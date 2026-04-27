import 'package:dartz/dartz.dart';

import '../../../../../../../core/errors/failures.dart';
import '../../entities/booking_status_response.dart';
import '../../repositories/instant_booking_repository.dart';

class GetBookingStatusUC {
  final InstantBookingRepository repository;
  const GetBookingStatusUC(this.repository);

  Future<Either<Failure, BookingStatusResponse>> call(String bookingId) =>
      repository.getBookingStatus(bookingId);
}
