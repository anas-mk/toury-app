import '../repositories/helper_bookings_repository.dart';
import '../entities/helper_booking_entities.dart';

class GetUpcomingBookingsUseCase {
  final HelperBookingsRepository repository;
  const GetUpcomingBookingsUseCase(this.repository);
  Future<List<HelperBooking>> call() => repository.getUpcomingBookings();
}
