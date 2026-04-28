import 'package:dartz/dartz.dart';

import '../../../../../../../core/errors/failures.dart';
import '../../entities/booking_detail.dart';
import '../../repositories/instant_booking_repository.dart';

class GetBookingDetailUC {
  final InstantBookingRepository repository;
  const GetBookingDetailUC(this.repository);

  Future<Either<Failure, BookingDetail>> call(String bookingId) =>
      repository.getBookingDetail(bookingId);
}
