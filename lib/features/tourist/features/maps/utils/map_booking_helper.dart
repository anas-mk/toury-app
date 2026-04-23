import '../../../../../../core/di/injection_container.dart';
import '../../user_booking/domain/entities/helper_entity.dart';
import '../../user_booking/domain/usecases/search_instant_helpers_usecase.dart';
import '../domain/entities/location.dart';

class MapBookingHelper {
  final SearchInstantHelpersUseCase _searchInstantHelpersUseCase;

  MapBookingHelper({SearchInstantHelpersUseCase? useCase})
      : _searchInstantHelpersUseCase = useCase ?? sl<SearchInstantHelpersUseCase>();

  /// Integrates map location with Instant Search API
  /// Passes the current map coordinates to the search endpoint
  Future<List<HelperEntity>> searchInstantHelpersFromLocation({
    required Location location,
    String pickupLocationName = 'Current Location',
  }) async {
    final result = await _searchInstantHelpersUseCase(
      SearchInstantHelpersParams(
        pickupLocation: pickupLocationName,
        lat: location.latitude,
        lng: location.longitude,
      ),
    );

    return result.fold(
      (failure) {
        // Handle error as needed, or rethrow
        throw Exception(failure.message);
      },
      (helpers) => helpers,
    );
  }
}
