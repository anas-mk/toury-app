import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/alternative_helper_entity.dart';
import '../repositories/user_booking_repository.dart';

class GetAlternativesUseCase {
  final UserBookingRepository repository;

  GetAlternativesUseCase(this.repository);

  Future<Either<Failure, List<AlternativeHelperEntity>>> call(String bookingId) {
    return repository.getAlternatives(bookingId);
  }
}
