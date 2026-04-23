import 'package:dartz/dartz.dart';
import 'package:signalr_netcore/hub_connection.dart';
import '../../../../../../core/errors/failures.dart';
import '../../data/models/location_models.dart';
import '../../data/repositories/helper_location_repository_impl.dart';

class SendLocationUseCase {
  final HelperLocationRepository repository;
  SendLocationUseCase(this.repository);
  Future<Either<Failure, Unit>> call(HelperLocationUpdate update) => repository.updateLocation(update);
}

class GetLocationStatusUseCase {
  final HelperLocationRepository repository;
  GetLocationStatusUseCase(this.repository);
  Future<Either<Failure, HelperLocationStatus>> call() => repository.getStatus();
}

class GetInstantEligibilityUseCase {
  final HelperLocationRepository repository;
  GetInstantEligibilityUseCase(this.repository);
  Future<Either<Failure, InstantEligibility>> call() => repository.getInstantEligibility();
}

class ConnectLocationHubUseCase {
  final HelperLocationRepository repository;
  ConnectLocationHubUseCase(this.repository);
  Future<void> call() => repository.connect();
}

class DisconnectLocationHubUseCase {
  final HelperLocationRepository repository;
  DisconnectLocationHubUseCase(this.repository);
  Future<void> call() => repository.disconnect();
}

class GetLocationConnectionStateUseCase {
  final HelperLocationRepository repository;
  GetLocationConnectionStateUseCase(this.repository);
  Stream<HubConnectionState> call() => repository.connectionState;
}
