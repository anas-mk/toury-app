import '../entities/helper_booking_entities.dart';
import '../entities/helper_earnings_entities.dart';
import '../repositories/helper_bookings_repository.dart';

class GetHelperDashboardUseCase {
  final HelperBookingsRepository repository;
  const GetHelperDashboardUseCase(this.repository);
  Future<HelperDashboard> call() => repository.getDashboard();
}

class UpdateAvailabilityUseCase {
  final HelperBookingsRepository repository;
  const UpdateAvailabilityUseCase(this.repository);
  Future<void> call(HelperAvailabilityState status) => repository.updateAvailability(status);
}

class GetIncomingRequestsUseCase {
  final HelperBookingsRepository repository;
  const GetIncomingRequestsUseCase(this.repository);
  Future<List<HelperBooking>> call() => repository.getRequests();
}

class GetRequestDetailsUseCase {
  final HelperBookingsRepository repository;
  const GetRequestDetailsUseCase(this.repository);
  Future<HelperBooking> call(String bookingId) => repository.getRequestDetails(bookingId);
}

class AcceptBookingUseCase {
  final HelperBookingsRepository repository;
  const AcceptBookingUseCase(this.repository);
  Future<HelperBooking> call(String bookingId) => repository.acceptRequest(bookingId);
}

class DeclineBookingUseCase {
  final HelperBookingsRepository repository;
  const DeclineBookingUseCase(this.repository);
  Future<void> call(String bookingId, {String? reason}) =>
      repository.declineRequest(bookingId, reason: reason);
}

class GetUpcomingBookingsUseCase {
  final HelperBookingsRepository repository;
  const GetUpcomingBookingsUseCase(this.repository);
  Future<List<HelperBooking>> call() => repository.getUpcomingBookings();
}

class GetActiveBookingUseCase {
  final HelperBookingsRepository repository;
  const GetActiveBookingUseCase(this.repository);
  Future<HelperBooking?> call() => repository.getActiveBooking();
}

class StartTripUseCase {
  final HelperBookingsRepository repository;
  const StartTripUseCase(this.repository);
  Future<void> call(String bookingId) => repository.startTrip(bookingId);
}

class EndTripUseCase {
  final HelperBookingsRepository repository;
  const EndTripUseCase(this.repository);
  Future<double> call(String bookingId) => repository.endTrip(bookingId);
}

class GetHelperHistoryUseCase {
  final HelperBookingsRepository repository;
  const GetHelperHistoryUseCase(this.repository);
  Future<List<HelperBooking>> call({
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 20,
  }) =>
      repository.getHistory(status: status, from: from, to: to, page: page, pageSize: pageSize);
}

class GetEarningsUseCase {
  final HelperBookingsRepository repository;
  const GetEarningsUseCase(this.repository);
  Future<HelperEarnings> call() => repository.getEarnings();
}

class GetHelperBookingDetailsUseCase {
  final HelperBookingsRepository repository;
  const GetHelperBookingDetailsUseCase(this.repository);
  Future<HelperBooking> call(String bookingId) => repository.getBookingDetails(bookingId);
}
