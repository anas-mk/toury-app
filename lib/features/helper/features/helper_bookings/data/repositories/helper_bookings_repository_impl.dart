import '../../domain/entities/helper_booking_entities.dart';
import '../../domain/entities/helper_earnings_entities.dart';
import '../../domain/repositories/helper_bookings_repository.dart';
import '../datasources/helper_bookings_remote_data_source.dart';

class HelperBookingsRepositoryImpl implements HelperBookingsRepository {
  final HelperBookingsRemoteDataSource remoteDataSource;
  const HelperBookingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<HelperDashboard> getDashboard() => remoteDataSource.getDashboard();

  @override
  Future<void> updateAvailability(AvailabilityStatus status) =>
      remoteDataSource.updateAvailability(status.toJson());

  @override
  Future<List<HelperBooking>> getRequests() => remoteDataSource.getRequests();

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
