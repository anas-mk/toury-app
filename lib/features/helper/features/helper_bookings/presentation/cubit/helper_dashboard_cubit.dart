import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_dashboard_entity.dart';
import '../../domain/entities/helper_availability_state.dart';
import '../../domain/usecases/helper_bookings_usecases.dart';
import 'dart:async';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';

// HELPER DASHBOARD CUBIT
abstract class HelperDashboardState extends Equatable {
  const HelperDashboardState();
  @override List<Object?> get props => [];
}
class HelperDashboardInitial extends HelperDashboardState { const HelperDashboardInitial(); }
class HelperDashboardLoading extends HelperDashboardState { const HelperDashboardLoading(); }
class HelperDashboardLoaded extends HelperDashboardState {
  final HelperDashboardEntity dashboard;
  const HelperDashboardLoaded(this.dashboard);
  @override List<Object?> get props => [dashboard];
}
class HelperDashboardError extends HelperDashboardState {
  final String message;
  const HelperDashboardError(this.message);
  @override List<Object?> get props => [message];
}

class HelperDashboardCubit extends Cubit<HelperDashboardState> {
  final GetHelperDashboardUseCase _getDashboard;
  final BookingTrackingHubService _hubService;
  StreamSubscription? _hubSub;
  bool _inFlight = false;
  bool _loadedOnce = false;
  Timer? _hubDebounce;

  HelperDashboardCubit(this._getDashboard, this._hubService) : super(const HelperDashboardInitial()) {
    _listenToHub();
  }

  void _listenToHub() {
    _hubSub?.cancel();
    _hubSub = _hubService.dashboardStream.listen((event) {
      if (state is HelperDashboardLoaded) {
        final current = (state as HelperDashboardLoaded).dashboard;
        final updated = current.copyWith(
          todayEarnings: (event['todayEarnings'] as num?)?.toDouble(),
          completedTripsTotal: event['totalTrips'] as int?,
          rating: (event['rating'] as num?)?.toDouble(),
          acceptanceRate: (event['acceptanceRate'] as num?)?.toDouble(),
        );
        emit(HelperDashboardLoaded(updated));
      } else {
        // Debounce hub bursts so we never thrash the UI / APIs.
        _hubDebounce?.cancel();
        _hubDebounce = Timer(const Duration(milliseconds: 800), () {
          if (isClosed) return;
          refresh(silent: true);
        });
      }
    });
  }

  /// Initial load for the dashboard screen.
  Future<void> loadOnce() async {
    if (_loadedOnce) return;
    _loadedOnce = true;
    await load();
  }

  /// Loads dashboard from API.
  ///
  /// - When [silent]=true and we already have data, we DON'T emit Loading.
  ///   This prevents dashboard subtree disposal (which was re-triggering other APIs).
  Future<void> load({bool silent = false}) async {
    if (_inFlight) return;
    _inFlight = true;

    final hasData = state is HelperDashboardLoaded;
    if (!silent || !hasData) {
      emit(const HelperDashboardLoading());
    }
    try {
      final dashboard = await _getDashboard();
      if (isClosed) return;
      emit(HelperDashboardLoaded(dashboard));
    } catch (e) {
      if (isClosed) return;
      emit(HelperDashboardError(e.toString()));
    } finally {
      _inFlight = false;
    }
  }

  Future<void> refresh({bool silent = true}) => load(silent: silent);

  void updateLocalAvailability(HelperAvailabilityState status) {
    if (state is HelperDashboardLoaded) {
      final current = (state as HelperDashboardLoaded).dashboard;
      if (isClosed) return;
      emit(HelperDashboardLoaded(current.copyWith(availabilityState: status)));
    }
  }

  @override
  Future<void> close() {
    _hubDebounce?.cancel();
    _hubSub?.cancel();
    return super.close();
  }
}

