import '../../domain/entities/booking_detail.dart';
import '../../domain/entities/booking_status.dart';
import 'json_helpers.dart';
import 'price_breakdown_model.dart';

class BookingHelperSummaryModel extends BookingHelperSummary {
  const BookingHelperSummaryModel({
    required super.helperId,
    required super.fullName,
    super.profileImageUrl,
    required super.rating,
    required super.completedTrips,
    super.phoneNumber,
  });

  factory BookingHelperSummaryModel.fromJson(Map<String, dynamic> json) {
    return BookingHelperSummaryModel(
      helperId: json['helperId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      profileImageUrl: json['profileImageUrl']?.toString(),
      rating: parseDouble(json['rating']),
      completedTrips: parseInt(json['completedTrips']),
      phoneNumber: json['phoneNumber']?.toString(),
    );
  }
}

class CurrentAssignmentModel extends CurrentAssignment {
  const CurrentAssignmentModel({
    required super.helperId,
    required super.helperName,
    required super.attemptOrder,
    required super.responseStatus,
    super.sentAt,
    super.expiresAt,
  });

  factory CurrentAssignmentModel.fromJson(Map<String, dynamic> json) {
    return CurrentAssignmentModel(
      helperId: json['helperId']?.toString() ?? '',
      helperName: json['helperName']?.toString() ?? '',
      attemptOrder: parseInt(json['attemptOrder']),
      responseStatus: json['responseStatus']?.toString() ?? 'Pending',
      sentAt: tryParseUtc(json['sentAt']),
      expiresAt: tryParseUtc(json['expiresAt']),
    );
  }
}

class BookingStatusHistoryItemModel extends BookingStatusHistoryItem {
  const BookingStatusHistoryItemModel({
    required super.oldStatus,
    required super.newStatus,
    super.changedAt,
    super.reason,
  });

  factory BookingStatusHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return BookingStatusHistoryItemModel(
      oldStatus: json['oldStatus']?.toString() ?? '',
      newStatus: json['newStatus']?.toString() ?? '',
      changedAt: tryParseUtc(json['changedAt']),
      reason: json['reason']?.toString(),
    );
  }
}

class BookingDetailModel extends BookingDetail {
  const BookingDetailModel({
    required super.bookingId,
    required super.bookingType,
    required super.status,
    required super.rawStatus,
    required super.paymentStatus,
    super.destinationCity,
    super.requestedDate,
    super.startTime,
    required super.durationInMinutes,
    super.requestedLanguage,
    required super.requiresCar,
    required super.travelersCount,
    super.meetingPointType,
    required super.pickupLocationName,
    super.pickupAddress,
    required super.pickupLatitude,
    required super.pickupLongitude,
    super.destinationName,
    super.destinationLatitude,
    super.destinationLongitude,
    super.notes,
    super.estimatedPrice,
    super.finalPrice,
    super.depositAmount,
    super.remainingAmount,
    required super.depositPaid,
    required super.remainingPaid,
    required super.depositForfeited,
    super.priceBreakdown,
    super.helper,
    super.currentAssignment,
    required super.assignmentAttemptCount,
    required super.chatEnabled,
    required super.paymentRequired,
    required super.canCancel,
    super.cancellationReason,
    super.createdAt,
    super.acceptedAt,
    super.confirmedAt,
    super.startedAt,
    super.completedAt,
    super.cancelledAt,
    super.responseDeadline,
    required super.statusHistory,
  });

  factory BookingDetailModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString() ?? 'Unknown';
    final breakdown = json['priceBreakdown'];
    final helper = json['helper'];
    final assignment = json['currentAssignment'];

    return BookingDetailModel(
      bookingId: json['bookingId']?.toString() ?? '',
      bookingType: json['bookingType']?.toString() ?? 'Instant',
      status: BookingStatus.parse(rawStatus),
      rawStatus: rawStatus,
      paymentStatus:
          PaymentStatusWire.parse(json['paymentStatus']?.toString()),
      destinationCity: json['destinationCity']?.toString(),
      requestedDate: tryParseUtc(json['requestedDate']),
      startTime: json['startTime']?.toString(),
      durationInMinutes: parseInt(json['durationInMinutes']),
      requestedLanguage: json['requestedLanguage']?.toString(),
      requiresCar: parseBool(json['requiresCar']),
      travelersCount: parseInt(json['travelersCount'], fallback: 1),
      meetingPointType: json['meetingPointType']?.toString(),
      pickupLocationName: json['pickupLocationName']?.toString() ?? '',
      pickupAddress: json['pickupAddress']?.toString(),
      pickupLatitude: parseDouble(json['pickupLatitude']),
      pickupLongitude: parseDouble(json['pickupLongitude']),
      destinationName: json['destinationName']?.toString(),
      destinationLatitude: parseDoubleOrNull(json['destinationLatitude']),
      destinationLongitude: parseDoubleOrNull(json['destinationLongitude']),
      notes: json['notes']?.toString(),
      estimatedPrice: parseDoubleOrNull(json['estimatedPrice']),
      finalPrice: parseDoubleOrNull(json['finalPrice']),
      depositAmount: parseDoubleOrNull(json['depositAmount']),
      remainingAmount: parseDoubleOrNull(json['remainingAmount']),
      depositPaid: parseBool(json['depositPaid']),
      remainingPaid: parseBool(json['remainingPaid']),
      depositForfeited: parseBool(json['depositForfeited']),
      priceBreakdown: breakdown is Map<String, dynamic>
          ? PriceBreakdownModel.fromJson(breakdown)
          : null,
      helper: helper is Map<String, dynamic>
          ? BookingHelperSummaryModel.fromJson(helper)
          : null,
      currentAssignment: assignment is Map<String, dynamic>
          ? CurrentAssignmentModel.fromJson(assignment)
          : null,
      assignmentAttemptCount: parseInt(json['assignmentAttemptCount']),
      chatEnabled: parseBool(json['chatEnabled']),
      paymentRequired: parseBool(json['paymentRequired']),
      canCancel: parseBool(json['canCancel']),
      cancellationReason: json['cancellationReason']?.toString(),
      createdAt: tryParseUtc(json['createdAt']),
      acceptedAt: tryParseUtc(json['acceptedAt']),
      confirmedAt: tryParseUtc(json['confirmedAt']),
      startedAt: tryParseUtc(json['startedAt']),
      completedAt: tryParseUtc(json['completedAt']),
      cancelledAt: tryParseUtc(json['cancelledAt']),
      responseDeadline: tryParseUtc(json['responseDeadline']),
      statusHistory: (json['statusHistory'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(BookingStatusHistoryItemModel.fromJson)
              .toList() ??
          const [],
    );
  }
}
