import '../entities/helper_location_entities.dart';

abstract class HelperLocationRepository {
  Future<void> updateLocation(HelperLocation location);
  Future<LocationStatus> getLocationStatus();
  Future<InstantEligibility> getInstantEligibility();
  
  // Real-time
  Future<void> connectSignalR(String token);
  Future<void> disconnectSignalR();
  Future<void> streamLocationViaSignalR(HelperLocation location);
  Stream<dynamic> get signalRStateStream;
}
