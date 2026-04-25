import 'package:equatable/equatable.dart';

enum AvailabilityStatus {
  availableNow,
  scheduledOnly,
  busy,
  offline;

  String toJson() => name;
  static AvailabilityStatus fromJson(String json) => 
      AvailabilityStatus.values.firstWhere((e) => e.name == json, orElse: () => AvailabilityStatus.offline);
}

class HelperDashboard extends Equatable {
  final AvailabilityStatus availabilityState;
  final double todayEarnings;
  final int pendingRequestsCount;
  final int upcomingTripsCount;
  final int completedTripsTotal;
  final double rating;
  final int ratingCount;
  final double acceptanceRate;
  final HelperBooking? activeTrip;

  const HelperDashboard({
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

class HelperBooking extends Equatable {
  final String id;
  final String travelerName;
  final String? travelerImage;
  final String pickupLocation;
  final String destinationLocation;
  final double pickupLat;
  final double pickupLng;
  final double destinationLat;
  final double destinationLng;
  final DateTime startTime;
  final DateTime? endTime;
  final double payout;
  final String status;
  final String? language;
  final String? notes;
  final DateTime responseDeadline;
  final bool isInstant;

  const HelperBooking({
    required this.id,
    required this.travelerName,
    this.travelerImage,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.startTime,
    this.endTime,
    required this.payout,
    required this.status,
    this.language,
    this.notes,
    required this.responseDeadline,
    required this.isInstant,
  });

  @override
  List<Object?> get props => [
        id,
        travelerName,
        travelerImage,
        pickupLocation,
        destinationLocation,
        pickupLat,
        pickupLng,
        destinationLat,
        destinationLng,
        startTime,
        endTime,
        payout,
        status,
        language,
        notes,
        responseDeadline,
        isInstant,
      ];
}
