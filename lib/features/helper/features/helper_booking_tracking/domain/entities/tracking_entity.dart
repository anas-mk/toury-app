import 'package:equatable/equatable.dart';
import 'package:toury/core/models/tracking/tracking_point_entity.dart';

class TrackingEntity extends Equatable {
  final TrackingPointEntity? latestPoint;
  final List<TrackingPointEntity> history;
  final String status;
  final double? distanceToTarget;
  final int? etaMinutes;

  const TrackingEntity({
    this.latestPoint,
    required this.history,
    required this.status,
    this.distanceToTarget,
    this.etaMinutes,
  });

  @override
  List<Object?> get props => [latestPoint, history, status, distanceToTarget, etaMinutes];
}
