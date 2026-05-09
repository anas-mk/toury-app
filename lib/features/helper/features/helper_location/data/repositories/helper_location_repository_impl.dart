import '../../domain/entities/helper_location_entities.dart';
import '../../domain/entities/signalr_connection_state.dart';
import '../../domain/repositories/helper_location_repository.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import 'package:signalr_netcore/hub_connection.dart';
import '../datasources/helper_location_remote_data_source.dart';
import '../models/helper_location_models.dart';

class HelperLocationRepositoryImpl implements HelperLocationRepository {
  final HelperLocationRemoteDataSource remoteDataSource;
  final BookingTrackingHubService hubService;

  HelperLocationRepositoryImpl({
    required this.remoteDataSource,
    required this.hubService,
  });

  @override
  Future<LocationUpdateResponse> updateLocation(HelperLocation location) async {
    return await remoteDataSource.updateLocation(HelperLocationModel.fromEntity(location));
  }

  @override
  Future<LocationStatus> getLocationStatus() => remoteDataSource.getLocationStatus();

  @override
  Future<InstantEligibility> getInstantEligibility({
    double? pickupLat,
    double? pickupLng,
    String? language,
    bool? requiresCar,
  }) => remoteDataSource.getInstantEligibility(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        language: language,
        requiresCar: requiresCar,
      );

  @override
  Future<void> connectSignalR(String token) => hubService.connect(token);

  @override
  Future<void> disconnectSignalR() async {
    // Shared hub lifecycle is managed globally, never disconnect from a feature.
  }

  @override
  Future<void> streamLocationViaSignalR(HelperLocation location) async {
    await hubService.sendLocation(
      location.latitude,
      location.longitude,
      heading: location.heading,
      speedKmh: location.speedKmh,
      accuracyMeters: location.accuracyMeters,
    );
  }

  @override
  Stream<SignalRConnectionState> get signalRStateStream =>
      hubService.connectionStateStream.map(_mapHubState);

  SignalRConnectionState _mapHubState(HubConnectionState state) {
    switch (state) {
      case HubConnectionState.Connected:
        return SignalRConnectionState.connected;
      case HubConnectionState.Connecting:
      case HubConnectionState.Reconnecting:
        return SignalRConnectionState.connecting;
      case HubConnectionState.Disconnecting:
      case HubConnectionState.Disconnected:
        return SignalRConnectionState.disconnected;
    }
  }
}
