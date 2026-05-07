import '../../../../../../core/services/location_service.dart';
import '../entities/helper_location_entities.dart';

/// Use case to get the current GPS location of the helper.
class GetCurrentLocationUseCase {
  final LocationService locationService;

  GetCurrentLocationUseCase(this.locationService);

  Future<HelperLocation> execute() async {
    final pos = await locationService.getCurrentPosition();
    if (pos == null) {
      throw LocationPermissionDeniedException(
        'Location permission is required to go online',
      );
    }

    return HelperLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      heading: pos.heading,
      speedKmh: pos.speed,
      accuracyMeters: pos.accuracy,
      timestamp: pos.timestamp ?? DateTime.now(),
    );
  }
}

/// Exception thrown when location permission is denied
class LocationPermissionDeniedException implements Exception {
  final String message;
  LocationPermissionDeniedException(this.message);
  
  @override
  String toString() => message;
}
