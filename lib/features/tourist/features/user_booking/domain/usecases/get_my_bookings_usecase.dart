import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/network/api_response.dart';
import '../entities/booking_entity.dart';
import '../repositories/user_booking_repository.dart';

class GetMyBookingsParams {
  final String? status;
  final String? type;
  final int page;
  final int pageSize;

  const GetMyBookingsParams({
    this.status,
    this.type,
    this.page = 1,
    this.pageSize = 10,
  });
}

class GetMyBookingsUseCase {
  final UserBookingRepository repository;

  GetMyBookingsUseCase(this.repository);

  Future<Either<Failure, PaginatedResponse<BookingEntity>>> call(GetMyBookingsParams params) {
    return repository.getMyBookings(
      status: params.status,
      type: params.type,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
