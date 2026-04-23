import '../../domain/entities/booking_status_entity.dart';

class BookingStatusModel extends BookingStatusEntity {
  const BookingStatusModel({
    required super.bookingId,
    required super.status,
    required super.updatedAt,
  });

  factory BookingStatusModel.fromJson(Map<String, dynamic> json) {
    return BookingStatusModel(
      bookingId: json['bookingId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'status': status,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
