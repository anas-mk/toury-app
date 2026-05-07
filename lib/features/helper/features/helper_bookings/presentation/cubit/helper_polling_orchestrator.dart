import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/features/helper/features/helper_bookings/domain/entities/helper_availability_state.dart';
import 'helper_dashboard_cubit.dart';
import 'active_booking_cubit.dart';
import 'incoming_requests_cubit.dart';
import '../../../helper_location/presentation/cubit/location_status_cubits.dart';

class HelperPollingOrchestrator extends Cubit<void> {
  final HelperDashboardCubit _dashCubit;
  final ActiveBookingCubit _activeCubit;
  final IncomingRequestsCubit _requestsCubit;
  final LocationStatusCubit _statusCubit;
  
  Timer? _timer;
  bool _started = false;

  HelperPollingOrchestrator(
    this._dashCubit,
    this._activeCubit,
    this._requestsCubit,
    this._statusCubit,
  ) : super(null);

  void start() {
    if (_started) return;
    _started = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_dashCubit.state is HelperDashboardLoaded) {
        final currentStatus = (_dashCubit.state as HelperDashboardLoaded).dashboard.availabilityState;
        if (currentStatus == HelperAvailabilityState.availableNow) {
          _dashCubit.refresh();
          _activeCubit.load(silent: true);
          _requestsCubit.load(silent: true);
          _statusCubit.loadStatus();
        }
      }
    });
  }

  void stop() {
    _started = false;
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
