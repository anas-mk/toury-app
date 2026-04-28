import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../data/models/paged_response_model.dart';
import '../entities/booking_detail_entity.dart';
import '../entities/helper_booking_entity.dart';
import '../entities/search_params.dart';

abstract class UserBookingRepository {
  Future<Either<Failure, List<HelperBookingEntity>>> searchScheduledHelpers(ScheduledSearchParams params);
  Future<Either<Failure, List<HelperBookingEntity>>> searchInstantHelpers(InstantSearchParams params);
  Future<Either<Failure, HelperBookingEntity>> getHelperProfile(String helperId);
  Future<Either<Failure, BookingDetailEntity>> createScheduledBooking(Map<String, dynamic> bookingData);
  Future<Either<Failure, BookingDetailEntity>> createInstantBooking(Map<String, dynamic> bookingData);
  Future<Either<Failure, BookingDetailEntity>> getBookingDetails(String bookingId);
  Future<Either<Failure, PagedResponse<BookingDetailEntity>>> getMyBookings({
    int page = 1,
    int pageSize = 10,
    String? status,
    String? type,
  });
  Future<Either<Failure, void>> cancelBooking(String bookingId, String reason);
  Future<Either<Failure, List<HelperBookingEntity>>> getAlternatives(String bookingId);
  Future<Either<Failure, String>> getBookingStatus(String bookingId);
}
