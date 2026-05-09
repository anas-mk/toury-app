import 'package:dartz/dartz.dart';

import '../../../../../../../core/errors/failures.dart';
import '../../entities/helper_booking_profile.dart';
import '../../repositories/instant_booking_repository.dart';

class GetHelperBookingProfileUC {
  final InstantBookingRepository repository;
  const GetHelperBookingProfileUC(this.repository);

  Future<Either<Failure, HelperBookingProfile>> call(String helperId) =>
      repository.getHelperBookingProfile(helperId);
}
