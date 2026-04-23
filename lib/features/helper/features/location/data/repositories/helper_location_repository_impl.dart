import 'package:dartz/dartz.dart';
import 'package:signalr_netcore/hub_connection.dart';
import '../../../../../../core/errors/failures.dart';
import '../datasources/helper_location_service.dart';
import '../models/location_models.dart';

abstract class HelperLocationRepository {
  Future<Either<Failure, Unit>> updateLocation(HelperLocationUpdate update);
  Future<Either<Failure, HelperLocationStatus>> getStatus();
  Future<Either<Failure, InstantEligibility>> getInstantEligibility();
  Stream<HubConnectionState> get connectionState;
  Future<void> connect();
  Future<void> disconnect();
}

class HelperLocationRepositoryImpl implements HelperLocationRepository {
  final HelperLocationService service;
  HelperLocationRepositoryImpl(this.service);

  @override
  Stream<HubConnectionState> get connectionState => service.connectionState;

  @override
  Future<void> connect() => service.connect();

  @override
  Future<void> disconnect() => service.disconnect();

  @override
  Future<Either<Failure, Unit>> updateLocation(HelperLocationUpdate update) async {
    try {
      await service.updateLocation(update);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HelperLocationStatus>> getStatus() async {
    try {
      final result = await service.getStatus();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InstantEligibility>> getInstantEligibility() async {
    try {
      final result = await service.getInstantEligibility();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
