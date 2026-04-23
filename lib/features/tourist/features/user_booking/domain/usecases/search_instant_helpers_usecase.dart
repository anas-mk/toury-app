import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/helper_entity.dart';
import '../repositories/user_booking_repository.dart';

class SearchInstantHelpersParams {
  final String pickupLocation;
  final double lat;
  final double lng;

  const SearchInstantHelpersParams({
    required this.pickupLocation,
    required this.lat,
    required this.lng,
  });
}

class SearchInstantHelpersUseCase {
  final UserBookingRepository repository;

  SearchInstantHelpersUseCase(this.repository);

  Future<Either<Failure, List<HelperEntity>>> call(SearchInstantHelpersParams params) {
    return repository.searchInstantHelpers(
      pickupLocation: params.pickupLocation,
      lat: params.lat,
      lng: params.lng,
    );
  }
}
