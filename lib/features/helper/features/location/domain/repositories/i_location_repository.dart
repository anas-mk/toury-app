import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/location_point.dart';

abstract class ILocationRepository {
  /// Starts tracking the device location adaptively
  Future<Either<Failure, void>> startAdaptiveTracking();

  /// Stops tracking device location
  Future<Either<Failure, void>> stopTracking();

  /// Stream of live location updates
  Stream<LocationPoint> get locationStream;

  /// Broadcasts location point to backend/WebSocket
  Future<Either<Failure, void>> broadcastLocation(LocationPoint point, String bookingId);

  /// Caches location for offline queueing
  Future<Either<Failure, void>> cacheLocation(LocationPoint point);

  /// Syncs cached locations to the backend when connection restores
  Future<Either<Failure, void>> syncOfflineLocations(String bookingId);
}
