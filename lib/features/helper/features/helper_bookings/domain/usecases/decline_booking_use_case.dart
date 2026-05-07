import '../repositories/helper_bookings_repository.dart';

class DeclineBookingUseCase {
  final HelperBookingsRepository repository;
  const DeclineBookingUseCase(this.repository);
  Future<void> call(String bookingId, {String? reason}) =>
      repository.declineRequest(bookingId, reason: reason);
}
