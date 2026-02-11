import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/location.dart';
import '../entities/route_info.dart';

/// Domain Layer - Repository Interface
/// يحدد العقد (Contract) الذي يجب على الـ Data Layer تنفيذه
abstract class RoutingRepository {
  /// الحصول على المسار بين نقطتين
  Future<Either<Failure, RouteInfo>> getRoute({
    required Location start,
    required Location destination,
  });
}