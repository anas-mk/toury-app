import '../models/helper_booking_model.dart';

abstract class HelperBookingsService {
  Future<List<HelperBookingModel>> getRequests();
  Future<void> acceptBooking(String bookingId);
  Future<List<HelperBookingModel>> getUpcomingBookings();
  Future<void> startTrip(String bookingId);
  Future<void> endTrip(String bookingId);
  Future<HelperBookingModel?> getActiveBooking();
  Future<List<HelperBookingModel>> getHistory();
}
