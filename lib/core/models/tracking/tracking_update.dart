import 'tracking_point_entity.dart';

class TrackingUpdate {
  final TrackingPointEntity point;
  final String? status;
  final double? distanceToTarget;
  final int? etaMinutes;

  TrackingUpdate({
    required this.point,
    this.status,
    this.distanceToTarget,
    this.etaMinutes,
  });
}
