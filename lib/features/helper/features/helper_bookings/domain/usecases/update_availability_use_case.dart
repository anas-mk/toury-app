import 'package:toury/features/helper/features/helper_bookings/domain/entities/helper_availability_state.dart';

import '../repositories/helper_bookings_repository.dart';

class UpdateAvailabilityUseCase {
  final HelperBookingsRepository repository;
  const UpdateAvailabilityUseCase(this.repository);
  Future<void> call(HelperAvailabilityState status) => repository.updateAvailability(status);
}
