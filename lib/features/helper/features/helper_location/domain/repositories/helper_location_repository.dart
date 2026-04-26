import '../entities/helper_location_entities.dart';

abstract class HelperLocationRepository {
  Future<LocationUpdateResponse> updateLocation(HelperLocation location);
  Future<LocationStatus> getLocationStatus();
  Future<InstantEligibility> getInstantEligibility({
    double? pickupLat,
    double? pickupLng,
    String? language,
    bool? requiresCar,
  });
  
  // Real-time (SignalR)
  Future<void> connectSignalR(String token);
  Future<void> disconnectSignalR();
  Future<void> streamLocationViaSignalR(HelperLocation location);
  Stream<dynamic> get signalRStateStream;
}
