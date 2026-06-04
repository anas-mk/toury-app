import 'package:equatable/equatable.dart';

class TrackingPointEntity extends Equatable {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final DateTime timestamp;

  /// Backend-computed ETA + distance figures from
  /// `GET /api/booking/{bookingId}/tracking/latest`. These mirror the
  /// fields on `HelperLocationUpdateEvent` so the live-track screen
  /// can prime its UI on first paint without waiting for the next
  /// realtime tick.
  final double? distanceToPickupKm;
  final int? etaToPickupMinutes;
  final double? distanceToDestinationKm;
  final int? etaToDestinationMinutes;

  /// `"ToPickup" | "ToDestination" | "OnTheWay" | "InProgress"` —
  /// raw backend phase string. Used to decide which ETA to surface.
  final String? phase;

  const TrackingPointEntity({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    required this.timestamp,
    this.distanceToPickupKm,
    this.etaToPickupMinutes,
    this.distanceToDestinationKm,
    this.etaToDestinationMinutes,
    this.phase,
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        heading,
        speed,
        timestamp,
        distanceToPickupKm,
        etaToPickupMinutes,
        distanceToDestinationKm,
        etaToDestinationMinutes,
        phase,
      ];
}
