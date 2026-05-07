import 'package:equatable/equatable.dart';
import 'active_trip_entity.dart';
import 'helper_availability_state.dart';

class HelperDashboardEntity extends Equatable {
  final HelperAvailabilityState availabilityState;
  final double todayEarnings;
  final int pendingRequestsCount;
  final int upcomingTripsCount;
  final int completedTripsTotal;
  final double rating;
  final int ratingCount;
  final double acceptanceRate;
  final ActiveTripEntity? activeTrip;

  const HelperDashboardEntity({
    required this.availabilityState,
    required this.todayEarnings,
    required this.pendingRequestsCount,
    required this.upcomingTripsCount,
    required this.completedTripsTotal,
    required this.rating,
    required this.ratingCount,
    required this.acceptanceRate,
    this.activeTrip,
  });

  HelperDashboardEntity copyWith({
    HelperAvailabilityState? availabilityState,
    double? todayEarnings,
    int? pendingRequestsCount,
    int? upcomingTripsCount,
    int? completedTripsTotal,
    double? rating,
    int? ratingCount,
    double? acceptanceRate,
    ActiveTripEntity? activeTrip,
  }) {
    return HelperDashboardEntity(
      availabilityState: availabilityState ?? this.availabilityState,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      pendingRequestsCount: pendingRequestsCount ?? this.pendingRequestsCount,
      upcomingTripsCount: upcomingTripsCount ?? this.upcomingTripsCount,
      completedTripsTotal: completedTripsTotal ?? this.completedTripsTotal,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
      activeTrip: activeTrip ?? this.activeTrip,
    );
  }

  @override
  List<Object?> get props => [
        availabilityState,
        todayEarnings,
        pendingRequestsCount,
        upcomingTripsCount,
        completedTripsTotal,
        rating,
        ratingCount,
        acceptanceRate,
        activeTrip,
      ];
}
