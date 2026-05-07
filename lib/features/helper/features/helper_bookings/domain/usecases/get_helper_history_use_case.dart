import '../repositories/helper_bookings_repository.dart';
import '../entities/helper_booking_entities.dart';

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
