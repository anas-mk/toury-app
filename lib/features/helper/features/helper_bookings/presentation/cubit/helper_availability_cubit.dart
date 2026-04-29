import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../../domain/entities/helper_availability_state.dart';
import '../../domain/entities/helper_earnings_entities.dart';
import '../../domain/usecases/helper_bookings_usecases.dart';
import 'dart:async';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';

// AVAILABILITY CUBIT
abstract class HelperAvailabilityStatus extends Equatable {
  const HelperAvailabilityStatus();
  @override List<Object?> get props => [];
}
class AvailabilityInitial extends HelperAvailabilityStatus { const AvailabilityInitial(); }
class AvailabilityUpdating extends HelperAvailabilityStatus { const AvailabilityUpdating(); }
class AvailabilityUpdated extends HelperAvailabilityStatus {
  final HelperAvailabilityState status;
  const AvailabilityUpdated(this.status);
  @override List<Object?> get props => [status];
}
class AvailabilityError extends HelperAvailabilityStatus {
  final String message;
  const AvailabilityError(this.message);
  @override List<Object?> get props => [message];
}

class HelperAvailabilityCubit extends Cubit<HelperAvailabilityStatus> {
  final UpdateAvailabilityUseCase _updateAvailability;
  HelperAvailabilityCubit(this._updateAvailability) : super(const AvailabilityInitial());

  Future<void> update(HelperAvailabilityState status) async {
    debugPrint('[Availability][UI] Tap: ${status.name}');
    if (state is AvailabilityUpdating) {
      debugPrint('[Availability][UI] Duplicate ignored');
      return;
    }
    
    final apiValue = status.toApiValue;
    debugPrint('[Availability][API] Sending: $apiValue');
    emit(const AvailabilityUpdating());
    try {
      await _updateAvailability(status);
      if (isClosed) return;
      debugPrint('[Availability][API] Response: Success -> $apiValue');
      debugPrint('[Availability][STATE] Final: ${status.name}');
      emit(AvailabilityUpdated(status));
    } catch (e) {
      if (isClosed) return;
      debugPrint('[Availability][API] Response: Error -> $e');
      emit(AvailabilityError(e.toString()));
    }
  }
}

