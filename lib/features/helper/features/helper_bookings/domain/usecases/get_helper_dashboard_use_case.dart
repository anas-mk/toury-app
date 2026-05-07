import '../repositories/helper_bookings_repository.dart';
import '../entities/helper_dashboard_entity.dart';

class GetHelperDashboardUseCase {
  final HelperBookingsRepository repository;
  const GetHelperDashboardUseCase(this.repository);
  Future<HelperDashboardEntity> call() => repository.getDashboard();
}
