import 'package:dartz/dartz.dart';

import '../../../../../../../core/errors/failures.dart';
import '../../entities/booking_detail.dart';
import '../../entities/create_instant_booking_request.dart';
import '../../repositories/instant_booking_repository.dart';

class CreateInstantBookingUC {
  final InstantBookingRepository repository;
  const CreateInstantBookingUC(this.repository);

  Future<Either<Failure, BookingDetail>> call(
    CreateInstantBookingRequest request,
  ) =>
      repository.createInstantBooking(request);
}
