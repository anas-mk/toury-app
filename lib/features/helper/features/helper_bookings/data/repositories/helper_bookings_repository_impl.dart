import '../../domain/entities/helper_booking_entities.dart';
import '../../domain/entities/helper_dashboard_entity.dart';
import '../../domain/entities/helper_availability_state.dart';
import '../../domain/entities/helper_earnings_entities.dart';
import '../../domain/repositories/helper_bookings_repository.dart';
import '../datasources/helper_bookings_remote_data_source.dart';
import '../models/helper_booking_models.dart';

class HelperBookingsRepositoryImpl implements HelperBookingsRepository {
  final HelperBookingsRemoteDataSource remoteDataSource;
  const HelperBookingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<HelperDashboardEntity> getDashboard() => remoteDataSource.getDashboard();

  @override
  Future<void> updateAvailability(HelperAvailabilityState status) =>
      remoteDataSource.updateAvailability(status.toApiValue);

  @override
  Future<PaginatedRequestsResponse> getRequests({
    String? type,
    int page = 1,
    int pageSize = 10,
  }) =>
      remoteDataSource.getRequests(
        type: type,
        page: page,
        pageSize: pageSize,
      );

  @override
  Future<HelperBooking> getRequestDetails(String bookingId) =>
      remoteDataSource.getRequestDetails(bookingId);

  @override
  Future<HelperBooking> acceptRequest(String bookingId) =>
      remoteDataSource.acceptRequest(bookingId);

  @override
  Future<void> declineRequest(String bookingId, {String? reason}) =>
      remoteDataSource.declineRequest(bookingId, reason: reason);

  @override
  Future<List<HelperBooking>> getUpcomingBookings() =>
      remoteDataSource.getUpcomingBookings();

  @override
  Future<HelperBooking?> getActiveBooking() => remoteDataSource.getActiveBooking();

  @override
  Future<void> startTrip(String bookingId) => remoteDataSource.startTrip(bookingId);

  @override
  Future<double> endTrip(String bookingId) => remoteDataSource.endTrip(bookingId);

  @override
  Future<List<HelperBooking>> getHistory({
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 20,
  }) =>
      remoteDataSource.getHistory(status: status, from: from, to: to, page: page, pageSize: pageSize);

  @override
  Future<HelperEarnings> getEarnings() => remoteDataSource.getEarnings();

  @override
  Future<HelperBooking> getBookingDetails(String bookingId) =>
      remoteDataSource.getBookingDetails(bookingId);
}
