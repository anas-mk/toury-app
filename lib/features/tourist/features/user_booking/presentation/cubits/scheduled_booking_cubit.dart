import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/entities/booking_detail_entity.dart';

abstract class ScheduledBookingState extends Equatable {
  const ScheduledBookingState();
  @override
  List<Object?> get props => [];
}
class ScheduledBookingInitial extends ScheduledBookingState {}
class ScheduledBookingLoading extends ScheduledBookingState {}
class ScheduledBookingSuccess extends ScheduledBookingState {
  final BookingDetailEntity booking;
  const ScheduledBookingSuccess(this.booking);
  @override
  List<Object?> get props => [booking];
}
class ScheduledBookingError extends ScheduledBookingState {
  final String message;
  const ScheduledBookingError(this.message);
  @override
  List<Object?> get props => [message];
}

class ScheduledBookingCubit extends Cubit<ScheduledBookingState> {
  final CreateScheduledBookingUseCase createScheduledBookingUseCase;

  ScheduledBookingCubit({
    required this.createScheduledBookingUseCase,
  }) : super(ScheduledBookingInitial());

  Future<void> createScheduled(Map<String, dynamic> params) async {
    emit(ScheduledBookingLoading());
    final result = await createScheduledBookingUseCase(params);
    result.fold(
      (failure) => emit(ScheduledBookingError(failure.message)),
      (booking) => emit(ScheduledBookingSuccess(booking)),
    );
  }
}
