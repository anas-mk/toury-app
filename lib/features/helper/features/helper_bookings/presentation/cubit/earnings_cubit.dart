import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../../domain/entities/helper_earnings_entities.dart';
import '../../domain/usecases/helper_bookings_usecases.dart';
import 'dart:async';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';

// EARNINGS CUBIT
abstract class EarningsState extends Equatable {
  const EarningsState();
  @override List<Object?> get props => [];
}
class EarningsInitial extends EarningsState { const EarningsInitial(); }
class EarningsLoading extends EarningsState { const EarningsLoading(); }
class EarningsLoaded extends EarningsState {
  final HelperEarnings earnings;
  const EarningsLoaded(this.earnings);
  @override List<Object?> get props => [earnings];
}
class EarningsError extends EarningsState {
  final String message;
  const EarningsError(this.message);
  @override List<Object?> get props => [message];
}

class EarningsCubit extends Cubit<EarningsState> {
  final GetEarningsUseCase _getEarnings;
  EarningsCubit(this._getEarnings) : super(const EarningsInitial());

  Future<void> load() async {
    emit(const EarningsLoading());
    try {
      final earnings = await _getEarnings();
      if (isClosed) return;
      emit(EarningsLoaded(earnings));
    } catch (e) {
      if (isClosed) return;
      emit(EarningsError(e.toString()));
    }
  }
}

