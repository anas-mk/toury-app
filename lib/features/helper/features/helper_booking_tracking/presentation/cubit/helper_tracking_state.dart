import 'package:equatable/equatable.dart';
import '../../domain/entities/tracking_entity.dart';

abstract class HelperTrackingState extends Equatable {
  const HelperTrackingState();

  @override
  List<Object?> get props => [];
}

class HelperTrackingInitial extends HelperTrackingState {}

class HelperTrackingLoading extends HelperTrackingState {}

class HelperTrackingLive extends HelperTrackingState {
  final TrackingEntity tracking;
  final bool isFollowing;

  const HelperTrackingLive({
    required this.tracking,
    this.isFollowing = true,
  });

  @override
  List<Object?> get props => [tracking, isFollowing];

  HelperTrackingLive copyWith({
    TrackingEntity? tracking,
    bool? isFollowing,
  }) {
    return HelperTrackingLive(
      tracking: tracking ?? this.tracking,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

class HelperTrackingError extends HelperTrackingState {
  final String message;
  const HelperTrackingError(this.message);

  @override
  List<Object?> get props => [message];
}
