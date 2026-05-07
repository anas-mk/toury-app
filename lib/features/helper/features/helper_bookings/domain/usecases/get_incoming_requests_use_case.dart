import '../repositories/helper_bookings_repository.dart';
import '../../data/models/helper_booking_models.dart';

class GetIncomingRequestsUseCase {
  final HelperBookingsRepository repository;
  const GetIncomingRequestsUseCase(this.repository);
  
  Future<PaginatedRequestsResponse> call({
    String? type,
    int page = 1,
    int pageSize = 10,
  }) =>
      repository.getRequests(
        type: type,
        page: page,
        pageSize: pageSize,
      );
}
