import 'package:equatable/equatable.dart';

import 'booking_status.dart';

/// Lightweight booking-status response used by the polling fallback.
class BookingStatusResponse extends Equatable {
  final String bookingId;
  final BookingStatus status;

  /// Raw status string from the backend, kept for logging / debugging.
  final String rawStatus;
  final String? currentHelperId;
  final String? currentHelperName;
  final DateTime? responseDeadline;
  final bool isInReassignment;
  final int assignmentAttemptCount;
  final bool paymentRequired;
  final PaymentStatusWire paymentStatus;
  final bool chatEnabled;

  const BookingStatusResponse({
    required this.bookingId,
    required this.status,
    required this.rawStatus,
    this.currentHelperId,
    this.currentHelperName,
    this.responseDeadline,
    required this.isInReassignment,
    required this.assignmentAttemptCount,
    required this.paymentRequired,
    required this.paymentStatus,
    required this.chatEnabled,
  });

  @override
  List<Object?> get props => [
        bookingId,
        status,
        rawStatus,
        currentHelperId,
        currentHelperName,
        responseDeadline,
        isInReassignment,
        assignmentAttemptCount,
        paymentRequired,
        paymentStatus,
        chatEnabled,
      ];
}
