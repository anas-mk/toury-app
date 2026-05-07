import 'package:equatable/equatable.dart';

import 'helper_search_result.dart';

class AssignmentAttempt extends Equatable {
  final int attemptOrder;
  final String helperName;

  /// One of: `Pending`, `Accepted`, `Declined`, `Expired`, `CancelledBySystem`.
  final String responseStatus;
  final DateTime? sentAt;
  final DateTime? respondedAt;

  const AssignmentAttempt({
    required this.attemptOrder,
    required this.helperName,
    required this.responseStatus,
    this.sentAt,
    this.respondedAt,
  });

  @override
  List<Object?> get props =>
      [attemptOrder, helperName, responseStatus, sentAt, respondedAt];
}

/// Response of `GET /user/bookings/{bookingId}/alternatives`.
class AlternativesResponse extends Equatable {
  final String bookingId;
  final String status;
  final String message;
  final bool autoRetryActive;
  final int attemptsMade;
  final int maxAttempts;
  final List<HelperSearchResult> alternativeHelpers;
  final List<AssignmentAttempt> assignmentHistory;

  const AlternativesResponse({
    required this.bookingId,
    required this.status,
    required this.message,
    required this.autoRetryActive,
    required this.attemptsMade,
    required this.maxAttempts,
    required this.alternativeHelpers,
    required this.assignmentHistory,
  });

  @override
  List<Object?> get props => [
        bookingId,
        status,
        message,
        autoRetryActive,
        attemptsMade,
        maxAttempts,
        alternativeHelpers,
        assignmentHistory,
      ];
}
