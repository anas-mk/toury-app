import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/helper_entity.dart';
import '../repositories/user_booking_repository.dart';

class GetHelperProfileUseCase {
  final UserBookingRepository repository;

  GetHelperProfileUseCase(this.repository);

  Future<Either<Failure, HelperEntity>> call(String helperId) {
    return repository.getHelperProfile(helperId);
  }
}
