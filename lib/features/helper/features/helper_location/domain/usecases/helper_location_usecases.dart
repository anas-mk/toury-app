import '../entities/helper_location_entities.dart';
import '../repositories/helper_location_repository.dart';

class UpdateLocationUseCase {
  final HelperLocationRepository repository;
  UpdateLocationUseCase(this.repository);

  Future<void> execute(HelperLocation location) => repository.updateLocation(location);
}

class GetLocationStatusUseCase {
  final HelperLocationRepository repository;
  GetLocationStatusUseCase(this.repository);

  Future<LocationStatus> execute() => repository.getLocationStatus();
}

class GetInstantEligibilityUseCase {
  final HelperLocationRepository repository;
  GetInstantEligibilityUseCase(this.repository);

  Future<InstantEligibility> execute() => repository.getInstantEligibility();
}

class StreamLocationUseCase {
  final HelperLocationRepository repository;
  StreamLocationUseCase(this.repository);

  Future<void> execute(HelperLocation location) => repository.streamLocationViaSignalR(location);
}

class ConnectSignalRUseCase {
  final HelperLocationRepository repository;
  ConnectSignalRUseCase(this.repository);

  Future<void> execute(String token) => repository.connectSignalR(token);
}

class DisconnectSignalRUseCase {
  final HelperLocationRepository repository;
  DisconnectSignalRUseCase(this.repository);

  Future<void> execute() => repository.disconnectSignalR();
}
