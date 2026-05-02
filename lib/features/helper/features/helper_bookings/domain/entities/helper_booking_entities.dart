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

  HelperBooking copyWith({
    String? id,
    String? bookingType,
    bool? isUrgent,
    String? travelerName,
    String? travelerCountry,
    String? travelerImage,
    String? destinationCity,
    String? pickupLocation,
    String? destinationLocation,
    double? pickupLat,
    double? pickupLng,
    double? destinationLat,
    double? destinationLng,
    DateTime? startTime,
    DateTime? endTime,
    int? durationInMinutes,
    bool? requiresCar,
    int? travelersCount,
    String? meetingPointType,
    double? payout,
    String? status,
    String? language,
    String? notes,
    int? attemptOrder,
    String? attemptStatus,
    DateTime? sentAt,
    DateTime? responseDeadline,
    bool? isExpired,
    bool? isInstant,
    DateTime? createdAt,
  }) {
    return HelperBooking(
      id: id ?? this.id,
      bookingType: bookingType ?? this.bookingType,
      isUrgent: isUrgent ?? this.isUrgent,
      travelerName: travelerName ?? this.travelerName,
      travelerCountry: travelerCountry ?? this.travelerCountry,
      travelerImage: travelerImage ?? this.travelerImage,
      destinationCity: destinationCity ?? this.destinationCity,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationInMinutes: durationInMinutes ?? this.durationInMinutes,
      requiresCar: requiresCar ?? this.requiresCar,
      travelersCount: travelersCount ?? this.travelersCount,
      meetingPointType: meetingPointType ?? this.meetingPointType,
      payout: payout ?? this.payout,
      status: status ?? this.status,
      language: language ?? this.language,
      notes: notes ?? this.notes,
      attemptOrder: attemptOrder ?? this.attemptOrder,
      attemptStatus: attemptStatus ?? this.attemptStatus,
      sentAt: sentAt ?? this.sentAt,
      responseDeadline: responseDeadline ?? this.responseDeadline,
      isExpired: isExpired ?? this.isExpired,
      isInstant: isInstant ?? this.isInstant,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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
