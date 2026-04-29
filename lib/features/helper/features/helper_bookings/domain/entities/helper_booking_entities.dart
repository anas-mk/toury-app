import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';


class HelperBooking extends Equatable {
  final String id;
  final String bookingType;
  final bool isUrgent;
  final String travelerName;
  final String? travelerCountry;
  final String? travelerImage;
  final String destinationCity;
  final String pickupLocation;
  final String destinationLocation;
  final double pickupLat;
  final double pickupLng;
  final double destinationLat;
  final double destinationLng;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationInMinutes;
  final bool requiresCar;
  final int travelersCount;
  final String? meetingPointType;
  final double payout;
  final String status;
  final String? language;
  final String? notes;
  final int attemptOrder;
  final String? attemptStatus;
  final DateTime? sentAt;
  final DateTime responseDeadline;
  final bool isExpired;
  final bool isInstant;
  final DateTime createdAt;

  const HelperBooking({
    required this.id,
    required this.bookingType,
    this.isUrgent = false,
    required this.travelerName,
    this.travelerCountry,
    this.travelerImage,
    required this.destinationCity,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.startTime,
    this.endTime,
    this.durationInMinutes = 0,
    this.requiresCar = false,
    this.travelersCount = 1,
    this.meetingPointType,
    required this.payout,
    required this.status,
    this.language,
    this.notes,
    this.attemptOrder = 0,
    this.attemptStatus,
    this.sentAt,
    required this.responseDeadline,
    this.isExpired = false,
    required this.isInstant,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        bookingType,
        isUrgent,
        travelerName,
        travelerCountry,
        travelerImage,
        destinationCity,
        pickupLocation,
        destinationLocation,
        pickupLat,
        pickupLng,
        destinationLat,
        destinationLng,
        startTime,
        endTime,
        durationInMinutes,
        requiresCar,
        travelersCount,
        meetingPointType,
        payout,
        status,
        language,
        notes,
        attemptOrder,
        attemptStatus,
        sentAt,
        responseDeadline,
        isExpired,
        isInstant,
        createdAt,
      ];
}
