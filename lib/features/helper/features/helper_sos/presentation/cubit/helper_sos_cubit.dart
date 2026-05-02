import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/helper_sos_service.dart';

enum SosStatus { idle, activating, active, deactivating, completed, error }

class HelperSosState extends Equatable {
  final SosStatus status;
  final String? errorMessage;

  const HelperSosState({required this.status, this.errorMessage});

  @override
  List<Object?> get props => [status, errorMessage];
}

class HelperSosCubit extends Cubit<HelperSosState> {
  final HelperSosService sosService;

  HelperSosCubit({required this.sosService}) : super(const HelperSosState(status: SosStatus.idle));

  Future<void> activatePanic({
    required String bookingId,
    required double lat,
    required double lng,
    String? reason,
    String? note,
  }) async {
    emit(const HelperSosState(status: SosStatus.activating));
    try {
      await sosService.triggerPanicAlert(
        bookingId: bookingId,
        lat: lat,
        lng: lng,
        reason: reason,
        note: note,
      );
      emit(const HelperSosState(status: SosStatus.active));
    } catch (e) {
      emit(HelperSosState(status: SosStatus.error, errorMessage: e.toString()));
      rethrow;
    }
  }

  Future<void> deactivatePanic() async {
    emit(const HelperSosState(status: SosStatus.deactivating));
    try {
      await sosService.stopPanicAlert();
      emit(const HelperSosState(status: SosStatus.idle));
    } catch (e) {
      emit(HelperSosState(status: SosStatus.error, errorMessage: e.toString()));
      rethrow;
    }
  }
}
