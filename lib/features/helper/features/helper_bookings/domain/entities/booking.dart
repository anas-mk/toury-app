import 'package:equatable/equatable.dart';
import 'booking_status.dart';

class Booking extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userPhone;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String dropoffAddress;
  final BookingStatus status;
  final double estimatedFare;
  final DateTime createdAt;
  final String? cancelReason;

  const Booking({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.dropoffAddress,
    required this.status,
    required this.estimatedFare,
    required this.createdAt,
    this.cancelReason,
  });

  Booking copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupAddress,
    double? dropoffLatitude,
    double? dropoffLongitude,
    String? dropoffAddress,
    BookingStatus? status,
    double? estimatedFare,
    DateTime? createdAt,
    String? cancelReason,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
      dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      status: status ?? this.status,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      createdAt: createdAt ?? this.createdAt,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userPhone,
        pickupLatitude,
        pickupLongitude,
        pickupAddress,
        dropoffLatitude,
        dropoffLongitude,
        dropoffAddress,
        status,
        estimatedFare,
        createdAt,
        cancelReason,
      ];
}
