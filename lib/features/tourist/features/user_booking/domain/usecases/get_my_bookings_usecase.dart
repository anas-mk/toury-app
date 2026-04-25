import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../data/models/paged_response_model.dart';
import '../entities/booking_detail_entity.dart';
import '../repositories/user_booking_repository.dart';

class GetMyBookingsUseCase {
  final UserBookingRepository repository;

  GetMyBookingsUseCase(this.repository);

  Future<Either<Failure, PagedResponse<BookingDetailEntity>>> call({int page = 1, int pageSize = 10, String? status}) async {
    return await repository.getMyBookings(page: page, pageSize: pageSize, status: status);
  }
}
