import '../repositories/helper_bookings_repository.dart';
import '../entities/helper_booking_entities.dart';

class AcceptBookingUseCase {
  final HelperBookingsRepository repository;
  const AcceptBookingUseCase(this.repository);
  Future<HelperBooking> call(String bookingId) => repository.acceptRequest(bookingId);
}
