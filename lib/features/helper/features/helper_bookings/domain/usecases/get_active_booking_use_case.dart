import '../repositories/helper_bookings_repository.dart';
import '../entities/helper_booking_entities.dart';

class GetActiveBookingUseCase {
  final HelperBookingsRepository repository;
  const GetActiveBookingUseCase(this.repository);
  Future<HelperBooking?> call() => repository.getActiveBooking();
}
