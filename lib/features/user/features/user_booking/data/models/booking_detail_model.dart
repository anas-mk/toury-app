import '../../domain/entities/booking_detail_entity.dart';
import 'helper_booking_model.dart';

class BookingDetailModel extends BookingDetailEntity {
  const BookingDetailModel({
    required super.id,
    required super.status,
    required super.type,
    required super.requestedDate,
    super.startTime,
    required super.durationInMinutes,
    required super.destinationCity,
    super.pickupLocationName,
    super.pickupLatitude,
    super.pickupLongitude,
    super.destinationName,
    super.destinationLatitude,
    super.destinationLongitude,
    super.helper,
    super.estimatedPrice,
    super.finalPrice,
    super.currency,
    super.notes,
    required super.chatEnabled,
    required super.timeline,
    super.paymentStatus,
    super.priceBreakdown,
    super.currentAssignment,
    super.assignmentAttemptCount = 0,
    super.paymentRequired = false,
    super.canCancel = false,
    super.createdAt,
    super.acceptedAt,
    super.confirmedAt,
    super.startedAt,
    super.completedAt,
    super.cancelledAt,
  });

  factory BookingDetailModel.fromJson(Map<String, dynamic> json) {
    return BookingDetailModel(
      id: json['bookingId']?.toString() ?? json['id']?.toString() ?? '',
      status: _parseStatus(json['status']),
      type: _parseType(json['bookingType'] ?? json['type']),
      requestedDate: DateTime.parse(json['requestedDate']),
      startTime: json['startTime'],
      durationInMinutes: json['durationInMinutes'] ?? 0,
      destinationCity: json['destinationCity'] ?? '',
      pickupLocationName: json['pickupLocationName'],
      pickupLatitude: json['pickupLatitude'] != null ? (json['pickupLatitude'] as num).toDouble() : null,
      pickupLongitude: json['pickupLongitude'] != null ? (json['pickupLongitude'] as num).toDouble() : null,
      destinationName: json['destinationName'],
      destinationLatitude: json['destinationLatitude'] != null ? (json['destinationLatitude'] as num).toDouble() : null,
      destinationLongitude: json['destinationLongitude'] != null ? (json['destinationLongitude'] as num).toDouble() : null,
      helper: json['helper'] != null ? HelperBookingModel.fromJson(json['helper']) : null,
      estimatedPrice: json['estimatedPrice'] != null ? (json['estimatedPrice'] as num).toDouble() : null,
      finalPrice: json['finalPrice'] != null ? (json['finalPrice'] as num).toDouble() : null,
      currency: json['priceBreakdown']?['currency'] ?? 'EGP',
      notes: json['notes'],
      chatEnabled: json['chatEnabled'] ?? false,
      timeline: (json['statusHistory'] as List? ?? json['timeline'] as List? ?? [])
          .map((e) => BookingTimelineStepModel.fromJson(e))
          .toList(),
      paymentStatus: json['paymentStatus'],
      priceBreakdown: json['priceBreakdown'] != null ? PriceBreakdownModel.fromJson(json['priceBreakdown']) : null,
      currentAssignment: json['currentAssignment'] != null ? AssignmentModel.fromJson(json['currentAssignment']) : null,
      assignmentAttemptCount: json['assignmentAttemptCount'] ?? 0,
      paymentRequired: json['paymentRequired'] ?? false,
      canCancel: json['canCancel'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
      confirmedAt: json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt']) : null,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
    );
  }

  static BookingStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pendinghelperresponse': return BookingStatus.pendingHelperResponse;
      case 'acceptedbyhelper': return BookingStatus.acceptedByHelper;
      case 'confirmedawaitingpayment': return BookingStatus.confirmedAwaitingPayment;
      case 'confirmedpaid': return BookingStatus.confirmedPaid;
      case 'upcoming': return BookingStatus.upcoming;
      case 'inprogress': return BookingStatus.inProgress;
      case 'completed': return BookingStatus.completed;
      case 'declinedbyhelper': return BookingStatus.declinedByHelper;
      case 'expirednoresponse': return BookingStatus.expiredNoResponse;
      case 'reassignmentinprogress': return BookingStatus.reassignmentInProgress;
      case 'waitingforuseraction': return BookingStatus.waitingForUserAction;
      case 'cancelledbyuser': return BookingStatus.cancelledByUser;
      case 'cancelledbyhelper': return BookingStatus.cancelledByHelper;
      case 'cancelledbysystem': return BookingStatus.cancelledBySystem;
      // Legacy fallbacks from older backend values.
      case 'pending': return BookingStatus.pendingHelperResponse;
      case 'confirmed': return BookingStatus.confirmedPaid;
      case 'expired': return BookingStatus.expiredNoResponse;
      case 'declined': return BookingStatus.declinedByHelper;
      default: return BookingStatus.pendingHelperResponse;
    }
  }

  static BookingType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'scheduled': return BookingType.scheduled;
      case 'instant': return BookingType.instant;
      default: return BookingType.scheduled;
    }
  }
}

class AssignmentModel extends AssignmentEntity {
  const AssignmentModel({
    required super.helperId,
    required super.helperName,
    required super.attemptOrder,
    required super.responseStatus,
    required super.sentAt,
    super.expiresAt,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      helperId: json['helperId'] ?? '',
      helperName: json['helperName'] ?? '',
      attemptOrder: json['attemptOrder'] ?? 0,
      responseStatus: json['responseStatus'] ?? '',
      sentAt: DateTime.parse(json['sentAt']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }
}

class BookingTimelineStepModel extends BookingTimelineStep {
  const BookingTimelineStepModel({
    required super.oldStatus,
    required super.newStatus,
    required super.changedAt,
    super.reason,
  });

  factory BookingTimelineStepModel.fromJson(Map<String, dynamic> json) {
    return BookingTimelineStepModel(
      oldStatus: json['oldStatus'] ?? '',
      newStatus: json['newStatus'] ?? '',
      changedAt: DateTime.parse(json['changedAt'] ?? json['timestamp']),
      reason: json['reason'] ?? json['description'],
    );
  }
}

class PriceBreakdownModel extends PriceBreakdownEntity {
  const PriceBreakdownModel({
    required super.currency,
    required super.basePrice,
    required super.distanceKm,
    required super.durationHours,
    required super.helperHourlyRate,
    required super.distanceCost,
    required super.durationCost,
    required super.subtotal,
    required super.finalEstimatedPrice,
    required super.rafiqCommissionAmount,
    required super.helperNetAmount,
  });

  factory PriceBreakdownModel.fromJson(Map<String, dynamic> json) {
    return PriceBreakdownModel(
      currency: json['currency'] ?? 'EGP',
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
      durationHours: (json['durationHours'] ?? 0.0).toDouble(),
      helperHourlyRate: (json['helperHourlyRate'] ?? 0.0).toDouble(),
      distanceCost: (json['distanceCost'] ?? 0.0).toDouble(),
      durationCost: (json['durationCost'] ?? 0.0).toDouble(),
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      finalEstimatedPrice: (json['finalEstimatedPrice'] ?? 0.0).toDouble(),
      rafiqCommissionAmount: (json['rafiqCommissionAmount'] ?? 0.0).toDouble(),
      helperNetAmount: (json['helperNetAmount'] ?? 0.0).toDouble(),
    );
  }
}
