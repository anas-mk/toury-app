import '../repositories/helper_bookings_repository.dart';
import '../entities/helper_booking_entities.dart';
import '../entities/helper_earnings_entities.dart';

class GetEarningsUseCase {
  final HelperBookingsRepository repository;
  const GetEarningsUseCase(this.repository);
  Future<HelperEarnings> call() => repository.getEarnings();
}
