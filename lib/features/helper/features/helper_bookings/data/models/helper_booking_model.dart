import '../../domain/entities/helper_booking_entity.dart';

class HelperBookingModel extends HelperBookingEntity {
  const HelperBookingModel({
    required super.id,
    required super.touristName,
    super.touristImage,
    required super.destination,
    required super.date,
    required super.status,
    required super.price,
    required super.durationInMinutes,
    required super.canStartTrip,
    super.lat,
    super.lng,
    super.address,
  });

  factory HelperBookingModel.fromJson(Map<String, dynamic> json) {
    return HelperBookingModel(
      id: json['id']?.toString() ?? '',
      touristName: json['touristName'] ?? 'Unknown',
      touristImage: json['touristImage'],
      destination: json['destination'] ?? '',
      date: DateTime.parse(json['date']),
      status: json['status'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationInMinutes: json['durationInMinutes'] ?? 0,
      canStartTrip: json['canStartTrip'] ?? false,
      lat: (json['latitude'] as num?)?.toDouble(),
      lng: (json['longitude'] as num?)?.toDouble(),
      address: json['address'],
    );
  }
}
