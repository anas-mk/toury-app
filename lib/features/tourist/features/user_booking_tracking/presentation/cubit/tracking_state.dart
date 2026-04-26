import 'package:equatable/equatable.dart';
import '../../domain/entities/tracking_entity.dart';
import '../../../../../../core/models/tracking/tracking_point_entity.dart';

abstract class TrackingState extends Equatable {
  const TrackingState();

  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TrackingState {}

class TrackingLoading extends TrackingState {}

class TrackingActive extends TrackingState {
  final TrackingEntity tracking;
  final TrackingPointEntity? latestPoint;

  const TrackingActive({required this.tracking, this.latestPoint});

  @override
  List<Object?> get props => [tracking, latestPoint];

  TrackingActive copyWith({
    TrackingEntity? tracking,
    TrackingPointEntity? latestPoint,
  }) {
    return TrackingActive(
      tracking: tracking ?? this.tracking,
      latestPoint: latestPoint ?? this.latestPoint,
    );
  }
}

class TrackingError extends TrackingState {
  final String message;

  const TrackingError(this.message);

  @override
  List<Object?> get props => [message];
}
