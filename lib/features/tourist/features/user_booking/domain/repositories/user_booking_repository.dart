import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/network/api_response.dart';
import '../entities/alternative_helper_entity.dart';
import '../entities/booking_entity.dart';
import '../entities/booking_status_entity.dart';
import '../entities/helper_entity.dart';

abstract class UserBookingRepository {
  Future<Either<Failure, List<HelperEntity>>> searchScheduledHelpers({
    required String destination,
    required DateTime date,
    required String language,
    required bool needArabic,
    required int durationInMinutes,
  });

  Future<Either<Failure, List<HelperEntity>>> searchInstantHelpers({
    required String pickupLocation,
    required double lat,
    required double lng,
  });

  Future<Either<Failure, HelperEntity>> getHelperProfile(String helperId);

  Future<Either<Failure, BookingEntity>> createScheduledBooking();
  Future<Either<Failure, BookingEntity>> createInstantBooking();

  Future<Either<Failure, BookingEntity>> getBookingDetails(String bookingId);

  Future<Either<Failure, PaginatedResponse<BookingEntity>>> getMyBookings({
    String? status,
    String? type,
    int page = 1,
    int pageSize = 10,
  });

  Future<Either<Failure, void>> cancelBooking(String bookingId, String reason);

  Future<Either<Failure, List<AlternativeHelperEntity>>> getAlternatives(String bookingId);

  Future<Either<Failure, BookingStatusEntity>> getBookingStatus(String bookingId);
}
