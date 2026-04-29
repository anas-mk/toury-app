import '../repositories/helper_bookings_repository.dart';
import '../entities/helper_booking_entities.dart';

class GetHelperBookingDetailsUseCase {
  final HelperBookingsRepository repository;
  const GetHelperBookingDetailsUseCase(this.repository);
  Future<HelperBooking> call(String bookingId) => repository.getBookingDetails(bookingId);
}
