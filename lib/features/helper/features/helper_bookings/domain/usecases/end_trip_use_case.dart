import '../repositories/helper_bookings_repository.dart';
import '../entities/helper_booking_entities.dart';

class EndTripUseCase {
  final HelperBookingsRepository repository;
  const EndTripUseCase(this.repository);
  Future<double> call(String bookingId) => repository.endTrip(bookingId);
}
