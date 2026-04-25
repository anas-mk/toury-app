import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum HelperAvailabilityState {
  availableNow,
  scheduledOnly,
  busy,
  offline;

  /// Maps Flutter enum values to the exact strings the backend expects.
  String get toApiValue {
    switch (this) {
      case HelperAvailabilityState.availableNow:
        return 'AvailableNow';
      case HelperAvailabilityState.scheduledOnly:
        return 'ScheduledOnly';
      case HelperAvailabilityState.offline:
        return 'Offline';
      case HelperAvailabilityState.busy:
        return 'Busy';
    }
  }

  /// Parses backend response values case-insensitively.
  static HelperAvailabilityState fromApiValue(String status) {
    switch (status.toLowerCase()) {
      case 'availablenow':
      case 'online':
        return HelperAvailabilityState.availableNow;
      case 'scheduledonly':
        return HelperAvailabilityState.scheduledOnly;
      case 'busy':
        return HelperAvailabilityState.busy;
      case 'offline':
        return HelperAvailabilityState.offline;
      default:
        debugPrint('[Availability][STATE] Unknown value received: $status');
        return HelperAvailabilityState.offline;
    }
  }
}

class HelperDashboard extends Equatable {
  final HelperAvailabilityState availabilityState;
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

  HelperDashboard copyWith({
    HelperAvailabilityState? availabilityState,
    double? todayEarnings,
    int? pendingRequestsCount,
    int? upcomingTripsCount,
    int? completedTripsTotal,
    double? rating,
    int? ratingCount,
    double? acceptanceRate,
    HelperBooking? activeTrip,
  }) {
    return HelperDashboard(
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
