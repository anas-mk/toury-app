import 'package:equatable/equatable.dart';

import '../../../domain/entities/meeting_point_type.dart';

/// Inputs the user provides AFTER picking a helper but BEFORE confirming
/// the scheduled booking on the review screen.
///
/// `destinationName` + `destinationLatitude/Longitude` are REQUIRED for
/// scheduled bookings (the backend always needs a destination geo-point
/// for distance calculation and helper-side navigation). The bottom sheet
/// guarantees these are non-null and inside `[-90..90]` / `[-180..180]`
/// before constructing this entity.
///
/// Pickup is OPTIONAL by design (Fix 3): a user planning a trip days in
/// advance often doesn't know yet where they'll be staying. If they enter
/// a pickup name but no coords, we still send the name; if they drop a pin,
/// BOTH coords go on the wire. If everything is empty we omit the keys
/// from the JSON payload (the backend treats absence ≠ 0,0).
class ScheduledTripConfig extends Equatable {
  /// Human-readable destination label (REQUIRED — never empty).
  final String destinationName;
  final double destinationLatitude;
  final double destinationLongitude;

  /// Meeting-point preset. Defaults to [MeetingPointType.custom].
  final MeetingPointType meetingPointType;

  /// Optional pickup label.
  final String? pickupLocationName;

  /// Optional pickup geo-point. If either coord is non-null, both must be
  /// (validated at call site before submitting).
  final double? pickupLatitude;
  final double? pickupLongitude;

  /// Free-form note for the helper (max 2000 chars).
  final String? notes;

  const ScheduledTripConfig({
    required this.destinationName,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.meetingPointType = MeetingPointType.custom,
    this.pickupLocationName,
    this.pickupLatitude,
    this.pickupLongitude,
    this.notes,
  });

  bool get hasPickupCoords =>
      pickupLatitude != null && pickupLongitude != null;

  ScheduledTripConfig copyWith({
    String? destinationName,
    double? destinationLatitude,
    double? destinationLongitude,
    MeetingPointType? meetingPointType,
    String? pickupLocationName,
    double? pickupLatitude,
    double? pickupLongitude,
    String? notes,
  }) {
    return ScheduledTripConfig(
      destinationName: destinationName ?? this.destinationName,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      meetingPointType: meetingPointType ?? this.meetingPointType,
      pickupLocationName: pickupLocationName ?? this.pickupLocationName,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        destinationName,
        destinationLatitude,
        destinationLongitude,
        meetingPointType,
        pickupLocationName,
        pickupLatitude,
        pickupLongitude,
        notes,
      ];
}