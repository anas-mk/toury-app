import 'package:equatable/equatable.dart';
import 'package:toury/core/models/tracking/tracking_point_entity.dart';

class TrackingEntity extends Equatable {
  final String bookingId;
  final TrackingPointEntity? latestPoint;
  final List<TrackingPointEntity> history;
  final String status; // OnTheWay, InProgress, etc.
  final double? distanceToTarget;
  final int? etaMinutes;

  const TrackingEntity({
    required this.bookingId,
    this.latestPoint,
    this.history = const [],
    required this.status,
    this.distanceToTarget,
    this.etaMinutes,
  });

  @override
  List<Object?> get props => [
        bookingId,
        latestPoint,
        history,
        status,
        distanceToTarget,
        etaMinutes,
      ];
}
