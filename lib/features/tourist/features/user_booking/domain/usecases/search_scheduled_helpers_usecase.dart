import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/helper_entity.dart';
import '../repositories/user_booking_repository.dart';

class SearchScheduledHelpersParams {
  final String destination;
  final DateTime date;
  final String language;
  final bool needArabic;
  final int durationInMinutes;

  const SearchScheduledHelpersParams({
    required this.destination,
    required this.date,
    required this.language,
    required this.needArabic,
    required this.durationInMinutes,
  });
}

class SearchScheduledHelpersUseCase {
  final UserBookingRepository repository;

  SearchScheduledHelpersUseCase(this.repository);

  Future<Either<Failure, List<HelperEntity>>> call(SearchScheduledHelpersParams params) {
    return repository.searchScheduledHelpers(
      destination: params.destination,
      date: params.date,
      language: params.language,
      needArabic: params.needArabic,
      durationInMinutes: params.durationInMinutes,
    );
  }
}
