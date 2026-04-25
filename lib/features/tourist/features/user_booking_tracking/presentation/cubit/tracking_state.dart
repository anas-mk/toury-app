import 'package:equatable/equatable.dart';
import '../../domain/entities/tracking_entity.dart';

abstract class TrackingState extends Equatable {
  const TrackingState();

  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TrackingState {}

class TrackingLoading extends TrackingState {}

class TrackingLive extends TrackingState {
  final TrackingEntity tracking;
  final bool isReconnecting;

  const TrackingLive({
    required this.tracking,
    this.isReconnecting = false,
  });

  TrackingLive copyWith({
    TrackingEntity? tracking,
    bool? isReconnecting,
  }) {
    return TrackingLive(
      tracking: tracking ?? this.tracking,
      isReconnecting: isReconnecting ?? this.isReconnecting,
    );
  }

  @override
  List<Object?> get props => [tracking, isReconnecting];
}

class TrackingError extends TrackingState {
  final String message;

  const TrackingError(this.message);

  @override
  List<Object?> get props => [message];
}
