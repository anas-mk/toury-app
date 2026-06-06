import '../entities/end_trip_result.dart';
import '../repositories/helper_bookings_repository.dart';

class EndTripUseCase {
  final HelperBookingsRepository repository;
  const EndTripUseCase(this.repository);

  Future<EndTripResult> call(String bookingId) =>
      repository.endTrip(bookingId);
}
