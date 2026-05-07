import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/booking_actions_usecase.dart';

abstract class CancelBookingState extends Equatable {
  const CancelBookingState();
  @override
  List<Object?> get props => [];
}
class CancelBookingInitial extends CancelBookingState {}
class CancelBookingLoading extends CancelBookingState {}
class CancelBookingSuccess extends CancelBookingState {}
class CancelBookingError extends CancelBookingState {
  final String message;
  const CancelBookingError(this.message);
  @override
  List<Object?> get props => [message];
}

class CancelBookingCubit extends Cubit<CancelBookingState> {
  final CancelBookingUseCase cancelBookingUseCase;

  CancelBookingCubit({required this.cancelBookingUseCase}) : super(CancelBookingInitial());

  Future<void> cancel(String bookingId, String reason) async {
    emit(CancelBookingLoading());
    final result = await cancelBookingUseCase(bookingId, reason);
    result.fold(
      (failure) => emit(CancelBookingError(failure.message)),
      (_) => emit(CancelBookingSuccess()),
    );
  }
}
