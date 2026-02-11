import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_data_source.dart';

/// Repository Implementation - Location
class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource dataSource;

  LocationRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, Location>> getCurrentLocation() async {
    try {
      final location = await dataSource.getCurrentLocation();
      return Right(location);
    } on LocationException catch (e) {
      return Left(LocationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Location>>> searchLocations(String query) async {
    try {
      final locations = await dataSource.searchLocations(query);
      return Right(locations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Stream<Location> watchCurrentLocation() {
    return dataSource.watchCurrentLocation();
  }
}