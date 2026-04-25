import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/helper_sos_service.dart';

enum SosStatus { idle, activating, active, completed, error }

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

  Future<void> activatePanic(double lat, double lng) async {
    emit(const HelperSosState(status: SosStatus.activating));
    try {
      await sosService.triggerPanicAlert(lat: lat, lng: lng);
      emit(const HelperSosState(status: SosStatus.active));
    } catch (e) {
      emit(HelperSosState(status: SosStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> deactivatePanic() async {
    try {
      await sosService.stopPanicAlert();
      emit(const HelperSosState(status: SosStatus.idle));
    } catch (e) {
      emit(HelperSosState(status: SosStatus.error, errorMessage: e.toString()));
    }
  }
}
