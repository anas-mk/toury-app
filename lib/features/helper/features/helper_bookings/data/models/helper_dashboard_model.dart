import '../../domain/entities/helper_dashboard_entity.dart';
import '../../domain/entities/helper_availability_state.dart';
import 'active_trip_model.dart';

class HelperDashboardModel extends HelperDashboardEntity {
  const HelperDashboardModel({
    required super.availabilityState,
    required super.todayEarnings,
    required super.pendingRequestsCount,
    required super.upcomingTripsCount,
    required super.completedTripsTotal,
    required super.rating,
    required super.ratingCount,
    required super.acceptanceRate,
    super.activeTrip,
  });

  factory HelperDashboardModel.fromJson(Map<String, dynamic> json) {
    return HelperDashboardModel(
      availabilityState: HelperAvailabilityState.fromApiValue(
        json['availabilityState'] ?? 'offline',
      ),
      todayEarnings: (json['todayEarnings'] ?? 0).toDouble(),
      pendingRequestsCount: json['pendingRequestsCount'] ?? 0,
      upcomingTripsCount: json['upcomingTripsCount'] ?? 0,
      completedTripsTotal: json['completedTripsTotal'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      acceptanceRate: (json['acceptanceRate'] ?? 0).toDouble(),
      activeTrip: json['activeTrip'] != null
          ? ActiveTripModel.fromJson(json['activeTrip'])
          : null,
    );
  }
}
