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
    if (isClosed) return;
    emit(BookingDetailsLoading());
    final result = await getBookingDetailsUseCase(bookingId);
    if (isClosed) return;
    result.fold(
      (failure) {
        if (!isClosed) emit(BookingDetailsError(failure.message));
      },
      (booking) async {
        if (isClosed) return;
        // If the booking already embeds helper info, use it directly.
        if (booking.helper != null) {
          if (!isClosed) emit(BookingDetailsLoaded(booking, booking.helper!));
          return;
        }
        // Fallback: fetch by the helper's own ID from the assignment.
        final helperId = booking.currentAssignment?.helperId;
        if (helperId == null) {
          if (!isClosed) emit(BookingDetailsError('Helper information not available'));
          return;
        }
        final helperResult = await getHelperProfileUseCase(helperId);
        if (isClosed) return;
        helperResult.fold(
          (failure) {
            if (!isClosed) emit(BookingDetailsError(failure.message));
          },
          (helper) {
            if (!isClosed) emit(BookingDetailsLoaded(booking, helper));
          },
        );
      },
    );
  }
}
