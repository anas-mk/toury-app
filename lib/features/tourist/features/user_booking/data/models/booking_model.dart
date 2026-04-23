import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.helperId,
    required super.touristId,
    required super.status,
    required super.type,
    required super.createdAt,
    super.scheduledDate,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      helperId: json['helperId']?.toString() ?? '',
      touristId: json['touristId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'helperId': helperId,
      'touristId': touristId,
      'status': status,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
    };
  }
}
