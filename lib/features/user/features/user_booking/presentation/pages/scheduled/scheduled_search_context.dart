import '../../../domain/entities/helper_booking_entity.dart';
import '../../../domain/entities/search_params.dart';

/// In-memory cache for the active scheduled search flow.
///
/// Search results pass [HelperBookingEntity] via GoRouter `extra`, but the
/// profile API does not return trip pricing (`hourlyRate` is often null).
/// This cache keeps the search estimate available on the profile screen even
/// if route extras are unavailable.
class ScheduledSearchContext {
  ScheduledSearchContext._();

  static final ScheduledSearchContext instance = ScheduledSearchContext._();

  ScheduledSearchParams? params;
  final Map<String, HelperBookingEntity> _helpers = {};

  void rememberHelper({
    required ScheduledSearchParams params,
    required HelperBookingEntity helper,
  }) {
    this.params = params;
    _helpers[helper.id] = helper;
  }

  void rememberResults({
    required ScheduledSearchParams params,
    required List<HelperBookingEntity> helpers,
  }) {
    this.params = params;
    for (final helper in helpers) {
      _helpers[helper.id] = helper;
    }
  }

  HelperBookingEntity? helperFor(String helperId) => _helpers[helperId];

  void clear() {
    params = null;
    _helpers.clear();
  }
}
