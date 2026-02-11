import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/location.dart';
import '../entities/route_info.dart';
import '../repositories/routing_repository.dart';

/// Use Case - الحصول على المسار بين نقطتين
class GetRoute implements UseCase<RouteInfo, RouteParams> {
  final RoutingRepository repository;

  GetRoute(this.repository);

  @override
  Future<Either<Failure, RouteInfo>> call(RouteParams params) async {
    return await repository.getRoute(
      start: params.start,
      destination: params.destination,
    );
  }
}

class RouteParams extends Equatable {
  final Location start;
  final Location destination;

  const RouteParams({
    required this.start,
    required this.destination,
  });

  @override
  List<Object?> get props => [start, destination];
}