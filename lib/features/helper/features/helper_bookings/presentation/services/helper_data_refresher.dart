import 'dart:async';
import 'package:flutter/foundation.dart';
import '../cubit/helper_dashboard_cubit.dart';
import '../cubit/active_booking_cubit.dart';
import '../cubit/incoming_requests_cubit.dart';
import '../../../helper_location/presentation/cubit/location_status_cubits.dart';

/// Centralized refresh manager to prevent duplicate API calls
/// 
/// This service ensures that:
/// - Only one refresh operation runs at a time (locking)
/// - Duplicate calls are ignored while a refresh is in progress
/// - All data fetching is coordinated in one place
class HelperDataRefresher {
  final HelperDashboardCubit _dashboardCubit;
  final ActiveBookingCubit _activeBookingCubit;
  final IncomingRequestsCubit _requestsCubit;
  final LocationStatusCubit _locationStatusCubit;

  bool _isFetching = false;
  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(seconds: 5);

  HelperDataRefresher({
    required HelperDashboardCubit dashboardCubit,
    required ActiveBookingCubit activeBookingCubit,
    required IncomingRequestsCubit requestsCubit,
    required LocationStatusCubit locationStatusCubit,
  })  : _dashboardCubit = dashboardCubit,
        _activeBookingCubit = activeBookingCubit,
        _requestsCubit = requestsCubit,
        _locationStatusCubit = locationStatusCubit;

  /// Refreshes all helper data with duplicate call prevention
  /// 
  /// Returns true if refresh was executed, false if skipped
  Future<bool> refreshAll({bool silent = true}) async {
    // Prevent duplicate calls
    if (_isFetching) {
      debugPrint('[DataRefresher] Refresh already in progress, skipping');
      return false;
    }

    // Debounce: prevent too frequent refreshes
    if (_lastRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastRefresh < _minRefreshInterval) {
        debugPrint('[DataRefresher] Refresh too soon (${timeSinceLastRefresh.inSeconds}s), skipping');
        return false;
      }
    }

    _isFetching = true;
    _lastRefreshTime = DateTime.now();
    debugPrint('[DataRefresher] Starting refresh...');

    try {
      // Execute all API calls in parallel for better performance
      await Future.wait([
        _dashboardCubit.refresh(silent: silent),
        _activeBookingCubit.load(silent: silent),
        _requestsCubit.load(silent: silent),
        _locationStatusCubit.loadStatus(),
      ]);

      debugPrint('[DataRefresher] Refresh completed successfully');
      return true;
    } catch (e) {
      debugPrint('[DataRefresher] Refresh failed: $e');
      return false;
    } finally {
      _isFetching = false;
    }
  }

  /// Refreshes only dashboard data (lighter operation)
  Future<bool> refreshDashboard({bool silent = true}) async {
    if (_isFetching) {
      debugPrint('[DataRefresher] Refresh in progress, skipping dashboard refresh');
      return false;
    }

    _isFetching = true;
    debugPrint('[DataRefresher] Refreshing dashboard only...');

    try {
      await _dashboardCubit.refresh(silent: silent);
      debugPrint('[DataRefresher] Dashboard refresh completed');
      return true;
    } catch (e) {
      debugPrint('[DataRefresher] Dashboard refresh failed: $e');
      return false;
    } finally {
      _isFetching = false;
    }
  }

  /// Refreshes only active booking and requests (for online helpers)
  Future<bool> refreshBookingData({bool silent = true}) async {
    if (_isFetching) {
      debugPrint('[DataRefresher] Refresh in progress, skipping booking refresh');
      return false;
    }

    _isFetching = true;
    debugPrint('[DataRefresher] Refreshing booking data...');

    try {
      await Future.wait([
        _activeBookingCubit.load(silent: silent),
        _requestsCubit.load(silent: silent),
      ]);
      debugPrint('[DataRefresher] Booking data refresh completed');
      return true;
    } catch (e) {
      debugPrint('[DataRefresher] Booking data refresh failed: $e');
      return false;
    } finally {
      _isFetching = false;
    }
  }

  /// Checks if a refresh is currently in progress
  bool get isRefreshing => _isFetching;

  /// Gets the time since last successful refresh
  Duration? get timeSinceLastRefresh {
    if (_lastRefreshTime == null) return null;
    return DateTime.now().difference(_lastRefreshTime!);
  }

  /// Resets the refresh state (useful for testing or force refresh)
  void reset() {
    _isFetching = false;
    _lastRefreshTime = null;
    debugPrint('[DataRefresher] State reset');
  }
}
