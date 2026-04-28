import 'package:dartz/dartz.dart';

import '../../../../../../../core/errors/failures.dart';
import '../../entities/helper_search_result.dart';
import '../../entities/instant_search_request.dart';
import '../../repositories/instant_booking_repository.dart';

class SearchInstantHelpersUC {
  final InstantBookingRepository repository;
  const SearchInstantHelpersUC(this.repository);

  Future<Either<Failure, List<HelperSearchResult>>> call(
    InstantSearchRequest request,
  ) =>
      repository.searchInstantHelpers(request);
}
