import '../repositories/helper_bookings_repository.dart';

class StartTripUseCase {
  final HelperBookingsRepository repository;
  const StartTripUseCase(this.repository);
  Future<void> call(String bookingId) => repository.startTrip(bookingId);
}
