import 'package:equatable/equatable.dart';
import 'helper_booking_entity.dart';

enum BookingStatus {
  pendingHelperResponse,
  acceptedByHelper,
  confirmedAwaitingPayment,
  confirmedPaid,
  upcoming,
  inProgress,
  completed,
  declinedByHelper,
  expiredNoResponse,
  reassignmentInProgress,
  waitingForUserAction,
  cancelledByUser,
  cancelledByHelper,
  cancelledBySystem,
}

enum BookingType {
  scheduled,
  instant,
}

class BookingDetailEntity extends Equatable {
  final String id;
  final BookingStatus status;
  final BookingType type;
  final DateTime requestedDate;
  final String? startTime;
  final int durationInMinutes;
  final String destinationCity;
  final String? pickupLocationName;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? destinationName;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final HelperBookingEntity? helper;
  final double? estimatedPrice;
  final double? finalPrice;
  final String? currency;
  final String? notes;
  final bool chatEnabled;
  final List<BookingTimelineStep> timeline;
  final String? paymentStatus;
  final PriceBreakdownEntity? priceBreakdown;
  final AssignmentEntity? currentAssignment;
  final int assignmentAttemptCount;
  final bool paymentRequired;
  final bool canCancel;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? confirmedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const BookingDetailEntity({
    required this.id,
    required this.status,
    required this.type,
    required this.requestedDate,
    this.startTime,
    required this.durationInMinutes,
    required this.destinationCity,
    this.pickupLocationName,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destinationName,
    this.destinationLatitude,
    this.destinationLongitude,
    this.helper,
    this.estimatedPrice,
    this.finalPrice,
    this.currency,
    this.notes,
    required this.chatEnabled,
    required this.timeline,
    this.paymentStatus,
    this.priceBreakdown,
    this.currentAssignment,
    this.assignmentAttemptCount = 0,
    this.paymentRequired = false,
    this.canCancel = false,
    this.createdAt,
    this.acceptedAt,
    this.confirmedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
  });

  @override
  List<Object?> get props => [
        id,
        status,
        type,
        requestedDate,
        startTime,
        durationInMinutes,
        destinationCity,
        pickupLocationName,
        pickupLatitude,
        pickupLongitude,
        destinationName,
        destinationLatitude,
        destinationLongitude,
        helper,
        estimatedPrice,
        finalPrice,
        currency,
        notes,
        chatEnabled,
        timeline,
        paymentStatus,
        priceBreakdown,
        currentAssignment,
        assignmentAttemptCount,
        paymentRequired,
        canCancel,
        createdAt,
        acceptedAt,
        confirmedAt,
        startedAt,
        completedAt,
        cancelledAt,
      ];
}

class AssignmentEntity extends Equatable {
  final String helperId;
  final String helperName;
  final int attemptOrder;
  final String responseStatus;
  final DateTime sentAt;
  final DateTime? expiresAt;

  const AssignmentEntity({
    required this.helperId,
    required this.helperName,
    required this.attemptOrder,
    required this.responseStatus,
    required this.sentAt,
    this.expiresAt,
  });

  @override
  List<Object?> get props => [helperId, helperName, attemptOrder, responseStatus, sentAt, expiresAt];
}

class BookingTimelineStep extends Equatable {
  final String oldStatus;
  final String newStatus;
  final DateTime changedAt;
  final String? reason;

  const BookingTimelineStep({
    required this.oldStatus,
    required this.newStatus,
    required this.changedAt,
    this.reason,
  });

  @override
  List<Object?> get props => [oldStatus, newStatus, changedAt, reason];
}

class PriceBreakdownEntity extends Equatable {
  final String currency;
  final double basePrice;
  final double distanceKm;
  final double durationHours;
  final double helperHourlyRate;
  final double distanceCost;
  final double durationCost;
  final double subtotal;
  final double finalEstimatedPrice;
  final double rafiqCommissionAmount;
  final double helperNetAmount;

  const PriceBreakdownEntity({
    required this.currency,
    required this.basePrice,
    required this.distanceKm,
    required this.durationHours,
    required this.helperHourlyRate,
    required this.distanceCost,
    required this.durationCost,
    required this.subtotal,
    required this.finalEstimatedPrice,
    required this.rafiqCommissionAmount,
    required this.helperNetAmount,
  });

  @override
  List<Object?> get props => [
        currency,
        basePrice,
        distanceKm,
        durationHours,
        helperHourlyRate,
        distanceCost,
        durationCost,
        subtotal,
        finalEstimatedPrice,
        rafiqCommissionAmount,
        helperNetAmount,
      ];
}
