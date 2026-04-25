import '../entities/helper_booking_entities.dart';
import '../entities/helper_earnings_entities.dart';

abstract class HelperBookingsRepository {
  Future<HelperDashboard> getDashboard();
  Future<void> updateAvailability(AvailabilityStatus status);
  Future<List<HelperBooking>> getRequests();
  Future<HelperBooking> getRequestDetails(String bookingId);
  Future<HelperBooking> acceptRequest(String bookingId);
  Future<void> declineRequest(String bookingId, {String? reason});
  Future<List<HelperBooking>> getUpcomingBookings();
  Future<HelperBooking?> getActiveBooking();
  Future<void> startTrip(String bookingId);
  Future<double> endTrip(String bookingId);
  Future<List<HelperBooking>> getHistory({
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 20,
  });
  Future<HelperEarnings> getEarnings();
  Future<HelperBooking> getBookingDetails(String bookingId);
}
