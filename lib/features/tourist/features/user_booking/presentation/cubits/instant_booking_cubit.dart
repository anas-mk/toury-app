import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:toury/features/tourist/features/user_booking/domain/usecases/booking_actions_usecase.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/entities/booking_detail_entity.dart';

abstract class InstantBookingState extends Equatable {
  const InstantBookingState();
  @override
  List<Object?> get props => [];
}
class InstantBookingInitial extends InstantBookingState {}
class InstantBookingLoading extends InstantBookingState {}
class InstantBookingSuccess extends InstantBookingState {
  final BookingDetailEntity booking;
  const InstantBookingSuccess(this.booking);
  @override
  List<Object?> get props => [booking];
}
class InstantBookingError extends InstantBookingState {
  final String message;
  const InstantBookingError(this.message);
  @override
  List<Object?> get props => [message];
}

class InstantBookingCubit extends Cubit<InstantBookingState> {
  final CreateInstantBookingUseCase createInstantBookingUseCase;
  final GetBookingStatusUseCase getBookingStatusUseCase;

  InstantBookingCubit({
    required this.createInstantBookingUseCase,
    required this.getBookingStatusUseCase,
  }) : super(InstantBookingInitial());

  Future<void> createInstant(Map<String, dynamic> params) async {
    emit(InstantBookingLoading());
    final result = await createInstantBookingUseCase(params);
    result.fold(
      (failure) => emit(InstantBookingError(failure.message)),
      (booking) => emit(InstantBookingSuccess(booking)),
    );
  }
}
