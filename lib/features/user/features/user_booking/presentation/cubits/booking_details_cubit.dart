import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/get_booking_details_usecase.dart';
import '../../domain/usecases/get_helper_profile_usecase.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../../domain/entities/helper_booking_entity.dart';

abstract class BookingDetailsState extends Equatable {
  const BookingDetailsState();
  @override
  List<Object?> get props => [];
}
class BookingDetailsInitial extends BookingDetailsState {}
class BookingDetailsLoading extends BookingDetailsState {}
class BookingDetailsLoaded extends BookingDetailsState {
  final BookingDetailEntity booking;
  final HelperBookingEntity helper;
  const BookingDetailsLoaded(this.booking, this.helper);
  @override
  List<Object?> get props => [booking, helper];
}
class BookingDetailsError extends BookingDetailsState {
  final String message;
  const BookingDetailsError(this.message);
  @override
  List<Object?> get props => [message];
}

class BookingDetailsCubit extends Cubit<BookingDetailsState> {
  final GetBookingDetailsUseCase getBookingDetailsUseCase;
  final GetHelperProfileUseCase getHelperProfileUseCase;

  BookingDetailsCubit({
    required this.getBookingDetailsUseCase,
    required this.getHelperProfileUseCase,
  }) : super(BookingDetailsInitial());

  Future<void> loadDetails(String bookingId) async {
    emit(BookingDetailsLoading());
    final result = await getBookingDetailsUseCase(bookingId);
    result.fold(
      (failure) => emit(BookingDetailsError(failure.message)),
      (booking) async {
        final helperResult = await getHelperProfileUseCase(booking.id);
        helperResult.fold(
          (failure) => emit(BookingDetailsError(failure.message)),
          (helper) => emit(BookingDetailsLoaded(booking, helper)),
        );
      },
    );
  }
}
