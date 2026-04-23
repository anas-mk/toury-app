import 'package:equatable/equatable.dart';
import '../../domain/entities/helper_booking_entity.dart';

class HelperBookingsState extends Equatable {
  final bool isLoading;
  final List<HelperBookingEntity> requests;
  final List<HelperBookingEntity> upcoming;
  final HelperBookingEntity? active;
  final List<HelperBookingEntity> history;
  final String? errorMessage;
  final String? actionLoadingId;

  const HelperBookingsState({
    this.isLoading = false,
    this.requests = const [],
    this.upcoming = const [],
    this.active,
    this.history = const [],
    this.errorMessage,
    this.actionLoadingId,
  });

  HelperBookingsState copyWith({
    bool? isLoading,
    List<HelperBookingEntity>? requests,
    List<HelperBookingEntity>? upcoming,
    HelperBookingEntity? active,
    List<HelperBookingEntity>? history,
    String? errorMessage,
    String? actionLoadingId,
  }) {
    return HelperBookingsState(
      isLoading: isLoading ?? this.isLoading,
      requests: requests ?? this.requests,
      upcoming: upcoming ?? this.upcoming,
      active: active ?? this.active,
      history: history ?? this.history,
      errorMessage: errorMessage,
      actionLoadingId: actionLoadingId,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        requests,
        upcoming,
        active,
        history,
        errorMessage,
        actionLoadingId,
      ];
}
