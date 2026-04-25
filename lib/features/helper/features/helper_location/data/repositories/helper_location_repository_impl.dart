import '../../domain/entities/helper_location_entities.dart';
import '../../domain/repositories/helper_location_repository.dart';
import '../datasources/helper_location_remote_data_source.dart';
import '../models/helper_location_models.dart';
import '../services/helper_location_signalr_service.dart';

class HelperLocationRepositoryImpl implements HelperLocationRepository {
  final HelperLocationRemoteDataSource remoteDataSource;
  final HelperLocationSignalRService signalRService;

  HelperLocationRepositoryImpl({
    required this.remoteDataSource,
    required this.signalRService,
  });

  @override
  Future<void> updateLocation(HelperLocation location) async {
    await remoteDataSource.updateLocation(HelperLocationModel.fromEntity(location));
  }

  @override
  Future<LocationStatus> getLocationStatus() => remoteDataSource.getLocationStatus();

  @override
  Future<InstantEligibility> getInstantEligibility() => remoteDataSource.getInstantEligibility();

  @override
  Future<void> connectSignalR(String token) => signalRService.connect(token);

  @override
  Future<void> disconnectSignalR() => signalRService.disconnect();

  @override
  Future<void> streamLocationViaSignalR(HelperLocation location) async {
    await signalRService.sendLocation(
      lat: location.latitude,
      lng: location.longitude,
      heading: location.heading,
      speed: location.speed,
    );
  }

  @override
  Stream<SignalRConnectionState> get signalRStateStream => signalRService.stateStream;
}
