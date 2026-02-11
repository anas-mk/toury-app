import '../../domain/entities/location.dart';
import '../../domain/entities/route_info.dart';
import '../models/route_info_model.dart';

/// Data Source Interface - Routing
abstract class RoutingDataSource {
  /// الحصول على المسار باستخدام OSRM API
  Future<RouteInfoModel> getRoute({
    required Location start,
    required Location destination,
  });
}