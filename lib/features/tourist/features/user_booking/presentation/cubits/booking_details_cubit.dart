import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../../domain/entities/helper_booking_entity.dart';
import '../../domain/usecases/get_booking_details_usecase.dart';
import '../../domain/usecases/get_helper_profile_usecase.dart';

part 'booking_details_state.dart';

class BookingDetailsCubit extends Cubit<BookingDetailsState> {
  final GetBookingDetailsUseCase getBookingDetailsUseCase;
  final GetHelperProfileUseCase getHelperProfileUseCase;

  BookingDetailsCubit({
    required this.getBookingDetailsUseCase,
    required this.getHelperProfileUseCase,
  }) : super(BookingDetailsInitial());

  Future<void> getBookingDetails(String bookingId) async {
    emit(BookingDetailsLoading());
    final result = await getBookingDetailsUseCase(bookingId);
    result.fold(
      (failure) => emit(BookingDetailsError(failure.message)),
      (booking) => emit(BookingDetailsLoaded(booking)),
    );
  }

  Future<void> getHelperProfile(String helperId) async {
    emit(HelperProfileLoading());
    final result = await getHelperProfileUseCase(helperId);
    result.fold(
      (failure) => emit(HelperProfileError(failure.message)),
      (helper) => emit(HelperProfileLoaded(helper)),
    );
  }
}
