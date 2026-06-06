import '../../domain/entities/end_trip_result.dart';
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
  Future<EndTripResult> endTrip(String bookingId) =>
      remoteDataSource.endTrip(bookingId);

  @override
  Future<List<HelperBooking>> getHistory({
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 20,
  }) async {
    final items = await remoteDataSource.getHistory(
      status: status,
      from: from,
      to: to,
      page: page,
      pageSize: pageSize,
    );
    return _enrichHistoryRoutes(items);
  }

  Future<List<HelperBooking>> _enrichHistoryRoutes(
    List<HelperBookingModel> items,
  ) async {
    return Future.wait(items.map(_enrichHistoryItem));
  }

  Future<HelperBooking> _enrichHistoryItem(HelperBookingModel item) async {
    if (_hasRouteLabels(item)) return item;

    try {
      final details = await remoteDataSource.getBookingDetails(item.id);
      return item.copyWith(
        pickupLocation: _firstNonEmpty([
          item.pickupLocation,
          details.pickupLocation,
        ]),
        destinationLocation: _firstNonEmpty([
          item.destinationLocation,
          details.destinationLocation,
          details.destinationCity,
          item.destinationCity,
        ]),
        pickupLat: details.pickupLat != 0 ? details.pickupLat : item.pickupLat,
        pickupLng: details.pickupLng != 0 ? details.pickupLng : item.pickupLng,
        destinationLat:
            details.destinationLat != 0 ? details.destinationLat : item.destinationLat,
        destinationLng:
            details.destinationLng != 0 ? details.destinationLng : item.destinationLng,
      );
    } catch (_) {
      return item.copyWith(
        destinationLocation: _firstNonEmpty([
          item.destinationLocation,
          item.destinationCity,
        ]),
      );
    }
  }

  bool _hasRouteLabels(HelperBooking booking) {
    final hasPickup = booking.pickupLocation.trim().isNotEmpty;
    final hasDestination = booking.destinationLocation.trim().isNotEmpty ||
        booking.destinationCity.trim().isNotEmpty;
    return hasPickup && hasDestination;
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  @override
  Future<HelperEarnings> getEarnings() => remoteDataSource.getEarnings();

  @override
  Future<HelperBooking> getBookingDetails(String bookingId) =>
      remoteDataSource.getBookingDetails(bookingId);
}
