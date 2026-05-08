// Status helpers for [HelperBooking].
//
// Centralizes the status string ↔ flag mapping that previously lived inline in
// `BookingCard`, `BookingStatusBanner`, `HelperBookingDetailsPage`,
// `ActiveBookingPage`, and `ActiveTrackingSheet`. Use these getters everywhere
// instead of duplicating the switch.

import 'helper_booking_entities.dart';

extension HelperBookingStatusX on HelperBooking {
  String get statusKey => status.toLowerCase();

  bool get isPending {
    final s = statusKey;
    return s == 'pending' || s == 'pendinghelperresponse';
  }

  bool get isConfirmed {
    final s = statusKey;
    return canStartTrip ||
        s == 'confirmed' ||
        s == 'accepted' ||
        s == 'acceptedbyhelper' ||
        s == 'confirmedpaid';
  }

  bool get isActive {
    final s = statusKey;
    return canEndTrip ||
        s == 'inprogress' ||
        s == 'started' ||
        s == 'active';
  }

  bool get isCompleted => statusKey == 'completed';

  bool get isCancelled {
    final s = statusKey;
    return s.contains('cancelled') ||
        s == 'rejected' ||
        s == 'declinedbyhelper';
  }

  /// Convenience for cases that want to know if a trip has effectively started
  /// (used by the live-tracking page where `canEndTrip` is the strongest hint).
  bool get isTripStarted => isActive;

  /// Whether the booking is in a "history" bucket (cannot be acted on).
  bool get isHistory => isCompleted || isCancelled;
}
