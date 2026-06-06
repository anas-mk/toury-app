// Status helpers for [HelperBooking].
//
// Centralizes the status string ↔ flag mapping that previously lived inline in
// `BookingCard`, `BookingStatusBanner`, `HelperBookingDetailsPage`,
// `ActiveBookingPage`, and `ActiveTrackingSheet`. Use these getters everywhere
// instead of duplicating the switch.

import 'package:geolocator/geolocator.dart';

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

extension HelperBookingRouteDisplayX on HelperBooking {
  String get pickupLocationLabel {
    if (pickupLocation.trim().isNotEmpty) return pickupLocation.trim();
    return 'Pickup location';
  }

  String get destinationLocationLabel {
    if (destinationLocation.trim().isNotEmpty) return destinationLocation.trim();
    if (destinationCity.trim().isNotEmpty) return destinationCity.trim();
    return 'Destination';
  }
}

/// Proximity rules for starting a trip — helper must be near the user pickup.
extension HelperBookingProximityX on HelperBooking {
  /// Helper may press "Start Trip" when within this radius of the user.
  static const double startTripRadiusMeters = 100;

  bool get hasValidPickupCoordinates {
    if (pickupLat == 0 && pickupLng == 0) return false;
    return pickupLat.abs() <= 90 && pickupLng.abs() <= 180;
  }

  double? distanceToUserMeters({
    required double helperLat,
    required double helperLng,
  }) {
    if (!hasValidPickupCoordinates) return null;
    return Geolocator.distanceBetween(
      helperLat,
      helperLng,
      pickupLat,
      pickupLng,
    );
  }

  /// True when the backend allows start, or helper GPS is within [startTripRadiusMeters].
  bool canHelperStartTripNow({
    required double? helperLat,
    required double? helperLng,
  }) {
    if (canStartTrip) return true;
    if (helperLat == null || helperLng == null) return false;
    final distance = distanceToUserMeters(
      helperLat: helperLat,
      helperLng: helperLng,
    );
    if (distance == null) return false;
    return distance <= startTripRadiusMeters;
  }
}
