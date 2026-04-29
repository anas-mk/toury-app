import 'package:equatable/equatable.dart';

class HelperBookingEntity extends Equatable {
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

  const HelperBookingEntity({
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
