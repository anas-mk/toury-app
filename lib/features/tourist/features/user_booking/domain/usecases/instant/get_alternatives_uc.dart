import 'package:dartz/dartz.dart';

import '../../../../../../../core/errors/failures.dart';
import '../../entities/alternatives_response.dart';
import '../../repositories/instant_booking_repository.dart';

class GetAlternativesUC {
  final InstantBookingRepository repository;
  const GetAlternativesUC(this.repository);

  Future<Either<Failure, AlternativesResponse>> call(String bookingId) =>
      repository.getAlternatives(bookingId);
}
