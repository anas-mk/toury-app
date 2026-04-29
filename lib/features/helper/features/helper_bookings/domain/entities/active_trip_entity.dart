import 'package:equatable/equatable.dart';

class ActiveTripEntity extends Equatable {
  final String bookingId;
  final String travelerName;
  final String destinationCity;
  final String pickupLocationName;
  final DateTime? startedAt;
  final int durationInMinutes;

  const ActiveTripEntity({
    required this.bookingId,
    required this.travelerName,
    required this.destinationCity,
    required this.pickupLocationName,
    this.startedAt,
    required this.durationInMinutes,
  });

  @override
  List<Object?> get props => [
        bookingId,
        travelerName,
        destinationCity,
        pickupLocationName,
        startedAt,
        durationInMinutes,
      ];
}
