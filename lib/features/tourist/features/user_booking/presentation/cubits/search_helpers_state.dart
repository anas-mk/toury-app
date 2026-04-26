import 'package:equatable/equatable.dart';
import '../../domain/entities/helper_booking_entity.dart';

abstract class SearchHelpersState extends Equatable {
  const SearchHelpersState();
  @override
  List<Object?> get props => [];
}

class SearchHelpersInitial extends SearchHelpersState {}

class SearchHelpersLoading extends SearchHelpersState {}

class SearchHelpersLoaded extends SearchHelpersState {
  final List<HelperBookingEntity> helpers;

  const SearchHelpersLoaded(this.helpers);

  @override
  List<Object?> get props => [helpers];
}

/// Enriched error state — carries context so the UI can render
/// the right CTA (e.g. "Open Settings" vs "Try Again").
class SearchHelpersError extends SearchHelpersState {
  final String message;

  /// True while the cubit is still fetching GPS in the background.
  final bool isLocating;

  /// True when permission is permanently denied → UI should show "Open Settings".
  final bool isPermissionPermanentlyDenied;

  /// True when the device GPS switch is off → UI should show "Enable Location".
  final bool isServiceDisabled;

  const SearchHelpersError(
    this.message, {
    this.isLocating = false,
    this.isPermissionPermanentlyDenied = false,
    this.isServiceDisabled = false,
  });

  @override
  List<Object?> get props => [
        message,
        isLocating,
        isPermissionPermanentlyDenied,
        isServiceDisabled,
      ];
}
