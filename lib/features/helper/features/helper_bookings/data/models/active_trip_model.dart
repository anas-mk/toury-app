import '../../domain/entities/active_trip_entity.dart';

class ActiveTripModel extends ActiveTripEntity {
  const ActiveTripModel({
    required super.bookingId,
    required super.travelerName,
    required super.destinationCity,
    required super.pickupLocationName,
    super.startedAt,
    required super.durationInMinutes,
  });

  factory ActiveTripModel.fromJson(Map<String, dynamic> json) {
    return ActiveTripModel(
      bookingId: json['bookingId'] ?? '',
      travelerName: json['travelerName'] ?? '',
      destinationCity: json['destinationCity'] ?? '',
      pickupLocationName: json['pickupLocationName'] ?? '',
      startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt']) : null,
      durationInMinutes: json['durationInMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'travelerName': travelerName,
      'destinationCity': destinationCity,
      'pickupLocationName': pickupLocationName,
      'startedAt': startedAt?.toIso8601String(),
      'durationInMinutes': durationInMinutes,
    };
  }
}
