
import '../../../../../../core/network/api_response.dart';
import '../models/alternative_helper_model.dart';
import '../models/booking_model.dart' show BookingModel;
import '../models/booking_status_model.dart';
import '../models/helper_model.dart';

abstract class UserBookingService {
  Future<List<HelperModel>> searchScheduledHelpers({
    required String destination,
    required DateTime date,
    required String language,
    required bool needArabic,
    required int durationInMinutes,
  });

  Future<List<HelperModel>> searchInstantHelpers({
    required String pickupLocation,
    required double lat,
    required double lng,
  });

  Future<HelperModel> getHelperProfile(String helperId);

  Future<BookingModel> createScheduledBooking();
  Future<BookingModel> createInstantBooking();

  Future<BookingModel> getBookingDetails(String bookingId);

  Future<PaginatedResponse<BookingModel>> getMyBookings({
    String? status,
    String? type,
    int page = 1,
    int pageSize = 10,
  });

  Future<void> cancelBooking(String bookingId, String reason);

  Future<List<AlternativeHelperModel>> getAlternatives(String bookingId);

  Future<BookingStatusModel> getBookingStatus(String bookingId);
}
