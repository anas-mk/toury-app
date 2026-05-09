import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failures.dart';
import '../entities/alternatives_response.dart';
import '../entities/booking_detail.dart';
import '../entities/booking_status_response.dart';
import '../entities/create_instant_booking_request.dart';
import '../entities/helper_booking_profile.dart';
import '../entities/helper_search_result.dart';
import '../entities/instant_search_request.dart';

/// Domain-level interface for everything the user-app needs to do an
/// Instant Trip Booking. Maps 1:1 to the REST contract under
/// `/user/bookings/instant/*` and `/user/bookings/{bookingId}/*`.
abstract class InstantBookingRepository {
  /// `POST /user/bookings/instant/search`
  Future<Either<Failure, List<HelperSearchResult>>> searchInstantHelpers(
    InstantSearchRequest request,
  );

  /// `GET /user/bookings/helpers/{helperId}/profile`
  Future<Either<Failure, HelperBookingProfile>> getHelperBookingProfile(
    String helperId,
  );

  /// `POST /user/bookings/instant`
  Future<Either<Failure, BookingDetail>> createInstantBooking(
    CreateInstantBookingRequest request,
  );

  /// `GET /user/bookings/{bookingId}/status`
  Future<Either<Failure, BookingStatusResponse>> getBookingStatus(
    String bookingId,
  );

  /// `GET /user/bookings/{bookingId}`
  Future<Either<Failure, BookingDetail>> getBookingDetail(String bookingId);

  /// `GET /user/bookings/{bookingId}/alternatives`
  Future<Either<Failure, AlternativesResponse>> getAlternatives(
    String bookingId,
  );

  /// `POST /user/bookings/{bookingId}/cancel`
  Future<Either<Failure, BookingDetail>> cancelBooking(
    String bookingId,
    String reason,
  );
}
