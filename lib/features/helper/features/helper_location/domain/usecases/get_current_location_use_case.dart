import '../entities/helper_location_entities.dart';
import '../../data/services/helper_location_tracker.dart';

/// Use case to get the current GPS location of the helper
/// This is used when the helper goes online to send their location to the backend
class GetCurrentLocationUseCase {
  final HelperLocationTracker locationTracker;

  GetCurrentLocationUseCase(this.locationTracker);

  /// Fetches the current GPS location
  /// Throws an exception if location permission is denied or location services are disabled
  Future<HelperLocation> execute() async {
    final hasPermission = await locationTracker.checkPermission();
    if (!hasPermission) {
      throw LocationPermissionDeniedException(
        'Location permission is required to go online',
      );
    }

    final locationModel = await locationTracker.getCurrentLocation();
    
    return HelperLocation(
      latitude: locationModel.latitude,
      longitude: locationModel.longitude,
      heading: locationModel.heading,
      speedKmh: locationModel.speedKmh,
      timestamp: locationModel.timestamp,
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
