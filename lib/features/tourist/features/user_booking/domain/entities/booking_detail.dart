import 'package:equatable/equatable.dart';

import 'booking_status.dart';
import 'price_breakdown.dart';

class BookingHelperSummary extends Equatable {
  final String helperId;
  final String fullName;
  final String? profileImageUrl;
  final double rating;
  final int completedTrips;
  final String? phoneNumber;

  const BookingHelperSummary({
    required this.helperId,
    required this.fullName,
    this.profileImageUrl,
    required this.rating,
    required this.completedTrips,
    this.phoneNumber,
  });

  @override
  List<Object?> get props =>
      [helperId, fullName, profileImageUrl, rating, completedTrips, phoneNumber];
}

class CurrentAssignment extends Equatable {
  final String helperId;
  final String helperName;
  final int attemptOrder;

  /// Raw response status: `Pending`, `Accepted`, `Declined`, `Expired`, …
  final String responseStatus;
  final DateTime? sentAt;
  final DateTime? expiresAt;

  const CurrentAssignment({
    required this.helperId,
    required this.helperName,
    required this.attemptOrder,
    required this.responseStatus,
    this.sentAt,
    this.expiresAt,
  });

  @override
  List<Object?> get props =>
      [helperId, helperName, attemptOrder, responseStatus, sentAt, expiresAt];
}

class BookingStatusHistoryItem extends Equatable {
  final String oldStatus;
  final String newStatus;
  final DateTime? changedAt;
  final String? reason;

  const BookingStatusHistoryItem({
    required this.oldStatus,
    required this.newStatus,
    this.changedAt,
    this.reason,
  });

  @override
  List<Object?> get props => [oldStatus, newStatus, changedAt, reason];
}

/// Full booking detail — `BookingDetailResponse` from the backend.
class BookingDetail extends Equatable {
  final String bookingId;
  final String bookingType; // "Instant" | "Scheduled"
  final BookingStatus status;
  final String rawStatus;
  final PaymentStatusWire paymentStatus;
  final String? destinationCity;
  final DateTime? requestedDate;
  final String? startTime; // "18:30:00"
  final int durationInMinutes;

  /// ISO 639-1 code or null.
  final String? requestedLanguage;
  final bool requiresCar;
  final int travelersCount;
  final String? meetingPointType;
  final String pickupLocationName;
  final String? pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String? destinationName;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String? notes;
  final double? estimatedPrice;
  final double? finalPrice;
  final double? depositAmount;
  final double? remainingAmount;
  final bool depositPaid;
  final bool remainingPaid;
  final bool depositForfeited;
  final PriceBreakdown? priceBreakdown;
  final BookingHelperSummary? helper;
  final CurrentAssignment? currentAssignment;
  final int assignmentAttemptCount;
  final bool chatEnabled;
  final bool paymentRequired;
  final bool canCancel;
  final String? cancellationReason;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? confirmedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? responseDeadline;
  final List<BookingStatusHistoryItem> statusHistory;

  const BookingDetail({
    required this.bookingId,
    required this.bookingType,
    required this.status,
    required this.rawStatus,
    required this.paymentStatus,
    this.destinationCity,
    this.requestedDate,
    this.startTime,
    required this.durationInMinutes,
    this.requestedLanguage,
    required this.requiresCar,
    required this.travelersCount,
    this.meetingPointType,
    required this.pickupLocationName,
    this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.destinationName,
    this.destinationLatitude,
    this.destinationLongitude,
    this.notes,
    this.estimatedPrice,
    this.finalPrice,
    this.depositAmount,
    this.remainingAmount,
    required this.depositPaid,
    required this.remainingPaid,
    required this.depositForfeited,
    this.priceBreakdown,
    this.helper,
    this.currentAssignment,
    required this.assignmentAttemptCount,
    required this.chatEnabled,
    required this.paymentRequired,
    required this.canCancel,
    this.cancellationReason,
    this.createdAt,
    this.acceptedAt,
    this.confirmedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.responseDeadline,
    required this.statusHistory,
  });

  @override
  List<Object?> get props => [
        bookingId,
        bookingType,
        status,
        rawStatus,
        paymentStatus,
        destinationCity,
        requestedDate,
        startTime,
        durationInMinutes,
        requestedLanguage,
        requiresCar,
        travelersCount,
        meetingPointType,
        pickupLocationName,
        pickupAddress,
        pickupLatitude,
        pickupLongitude,
        destinationName,
        destinationLatitude,
        destinationLongitude,
        notes,
        estimatedPrice,
        finalPrice,
        depositAmount,
        remainingAmount,
        depositPaid,
        remainingPaid,
        depositForfeited,
        priceBreakdown,
        helper,
        currentAssignment,
        assignmentAttemptCount,
        chatEnabled,
        paymentRequired,
        canCancel,
        cancellationReason,
        createdAt,
        acceptedAt,
        confirmedAt,
        startedAt,
        completedAt,
        cancelledAt,
        responseDeadline,
        statusHistory,
      ];
}
