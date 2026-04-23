import 'package:equatable/equatable.dart';

class HelperBookingEntity extends Equatable {
  final String id;
  final String touristName;
  final String? touristImage;
  final String destination;
  final DateTime date;
  final String status;
  final double price;
  final int durationInMinutes;
  final bool canStartTrip;
  final double? lat;
  final double? lng;
  final String? address;

  const HelperBookingEntity({
    required this.id,
    required this.touristName,
    this.touristImage,
    required this.destination,
    required this.date,
    required this.status,
    required this.price,
    required this.durationInMinutes,
    required this.canStartTrip,
    this.lat,
    this.lng,
    this.address,
  });

  @override
  List<Object?> get props => [
        id,
        touristName,
        touristImage,
        destination,
        date,
        status,
        price,
        durationInMinutes,
        canStartTrip,
        lat,
        lng,
        address,
      ];
}
