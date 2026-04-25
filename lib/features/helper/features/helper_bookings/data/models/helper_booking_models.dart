import '../../domain/entities/helper_booking_entities.dart';

class HelperBookingModel extends HelperBooking {
  const HelperBookingModel({
    required super.id,
    required super.travelerName,
    super.travelerImage,
    required super.pickupLocation,
    required super.destinationLocation,
    required super.pickupLat,
    required super.pickupLng,
    required super.destinationLat,
    required super.destinationLng,
    required super.startTime,
    super.endTime,
    required super.payout,
    required super.status,
    super.language,
    super.notes,
    required super.responseDeadline,
    required super.isInstant,
  });

  factory HelperBookingModel.fromJson(Map<String, dynamic> json) {
    return HelperBookingModel(
      id: json['id']?.toString() ?? '',
      travelerName: json['travelerName'] ?? 'Traveler',
      travelerImage: json['travelerImage'],
      pickupLocation: json['pickupLocation'] ?? '',
      destinationLocation: json['destinationLocation'] ?? '',
      pickupLat: (json['pickupLat'] as num?)?.toDouble() ?? 0.0,
      pickupLng: (json['pickupLng'] as num?)?.toDouble() ?? 0.0,
      destinationLat: (json['destinationLat'] as num?)?.toDouble() ?? 0.0,
      destinationLng: (json['destinationLng'] as num?)?.toDouble() ?? 0.0,
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      payout: (json['payout'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      language: json['language'],
      notes: json['notes'],
      responseDeadline: DateTime.parse(json['responseDeadline'] ?? DateTime.now().toIso8601String()),
      isInstant: json['isInstant'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'travelerName': travelerName,
      'travelerImage': travelerImage,
      'pickupLocation': pickupLocation,
      'destinationLocation': destinationLocation,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'payout': payout,
      'status': status,
      'language': language,
      'notes': notes,
      'responseDeadline': responseDeadline.toIso8601String(),
      'isInstant': isInstant,
    };
  }
}

class HelperDashboardModel extends HelperDashboard {
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
      availabilityState: AvailabilityStatus.fromJson(json['availabilityState'] ?? 'offline'),
      todayEarnings: (json['todayEarnings'] as num?)?.toDouble() ?? 0.0,
      pendingRequestsCount: json['pendingRequestsCount'] ?? 0,
      upcomingTripsCount: json['upcomingTripsCount'] ?? 0,
      completedTripsTotal: json['completedTripsTotal'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] ?? 0,
      acceptanceRate: (json['acceptanceRate'] as num?)?.toDouble() ?? 0.0,
      activeTrip: json['activeTrip'] != null ? HelperBookingModel.fromJson(json['activeTrip']) : null,
    );
  }
}
