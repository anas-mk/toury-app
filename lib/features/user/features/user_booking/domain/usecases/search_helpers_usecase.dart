import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/helper_booking_entity.dart';
import '../entities/search_params.dart';
import '../repositories/user_booking_repository.dart';

class SearchScheduledHelpersUseCase {
  final UserBookingRepository repository;

  SearchScheduledHelpersUseCase(this.repository);

  Future<Either<Failure, ({int availableCount, List<HelperBookingEntity> helpers})>> call(ScheduledSearchParams params) async {
    return await repository.searchScheduledHelpers(params);
  }
}

class SearchInstantHelpersUseCase {
  final UserBookingRepository repository;

  SearchInstantHelpersUseCase(this.repository);

  Future<Either<Failure, List<HelperBookingEntity>>> call(InstantSearchParams params) async {
    return await repository.searchInstantHelpers(params);
  }
}
