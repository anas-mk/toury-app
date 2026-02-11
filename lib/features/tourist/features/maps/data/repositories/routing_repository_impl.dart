import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/repositories/routing_repository.dart';
import '../datasources/routing_data_source.dart';

/// Repository Implementation - Routing
class RoutingRepositoryImpl implements RoutingRepository {
  final RoutingDataSource dataSource;

  RoutingRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, RouteInfo>> getRoute({
    required Location start,
    required Location destination,
  }) async {
    try {
      final route = await dataSource.getRoute(
        start: start,
        destination: destination,
      );
      return Right(route);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}