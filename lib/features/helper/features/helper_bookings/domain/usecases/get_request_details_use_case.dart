import '../repositories/helper_bookings_repository.dart';
import '../entities/helper_booking_entities.dart';

class GetRequestDetailsUseCase {
  final HelperBookingsRepository repository;
  const GetRequestDetailsUseCase(this.repository);
  Future<HelperBooking> call(String bookingId) => repository.getRequestDetails(bookingId);
}
