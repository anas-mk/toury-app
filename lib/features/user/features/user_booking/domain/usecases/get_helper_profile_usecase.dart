import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/helper_booking_entity.dart';
import '../repositories/user_booking_repository.dart';

class GetHelperProfileUseCase {
  final UserBookingRepository repository;

  GetHelperProfileUseCase(this.repository);

  Future<Either<Failure, HelperBookingEntity>> call(String helperId) async {
    return await repository.getHelperProfile(helperId);
  }
}
