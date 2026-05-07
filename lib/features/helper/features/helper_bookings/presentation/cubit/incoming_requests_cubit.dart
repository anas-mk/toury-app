import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../../domain/usecases/helper_bookings_usecases.dart';
import 'dart:async';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../../../../../core/di/injection_container.dart';

// ============================================================================
// INCOMING REQUESTS CUBIT - Enhanced with Pagination & Filtering
// ============================================================================

enum RequestFilterType {
  all,
  scheduled,
  instant;

  String? get apiValue {
    switch (this) {
      case RequestFilterType.all:
        return null;
      case RequestFilterType.scheduled:
        return 'Scheduled';
      case RequestFilterType.instant:
        return 'Instant';
    }
  }

  String get displayName {
    switch (this) {
      case RequestFilterType.all:
        return 'All';
      case RequestFilterType.scheduled:
        return 'Scheduled';
      case RequestFilterType.instant:
        return 'Instant';
    }
  }
}

abstract class IncomingRequestsState extends Equatable {
  const IncomingRequestsState();
  @override
  List<Object?> get props => [];
}

class IncomingRequestsInitial extends IncomingRequestsState {
  const IncomingRequestsInitial();
}

class IncomingRequestsLoading extends IncomingRequestsState {
  const IncomingRequestsLoading();
}

class IncomingRequestsLoadingMore extends IncomingRequestsState {
  final List<HelperBooking> currentRequests;
  final RequestFilterType filter;

  const IncomingRequestsLoadingMore(this.currentRequests, this.filter);

  @override
  List<Object?> get props => [currentRequests, filter];
}

class IncomingRequestsLoaded extends IncomingRequestsState {
  final List<HelperBooking> requests;
  final RequestFilterType filter;
  final int currentPage;
  final bool hasNextPage;
  final int totalCount;

  const IncomingRequestsLoaded({
    required this.requests,
    required this.filter,
    required this.currentPage,
    required this.hasNextPage,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [requests, filter, currentPage, hasNextPage, totalCount];

  IncomingRequestsLoaded copyWith({
    List<HelperBooking>? requests,
    RequestFilterType? filter,
    int? currentPage,
    bool? hasNextPage,
    int? totalCount,
  }) {
    return IncomingRequestsLoaded(
      requests: requests ?? this.requests,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class IncomingRequestsEmpty extends IncomingRequestsState {
  final RequestFilterType filter;

  const IncomingRequestsEmpty(this.filter);

  @override
  List<Object?> get props => [filter];
}

class IncomingRequestsError extends IncomingRequestsState {
  final String message;
  final RequestFilterType filter;

  const IncomingRequestsError(this.message, this.filter);

  @override
  List<Object?> get props => [message, filter];
}

class IncomingRequestsCubit extends Cubit<IncomingRequestsState> {
  final GetIncomingRequestsUseCase _getRequests;
  late final BookingTrackingHubService _hubService;
  StreamSubscription? _hubSub;
  Timer? _hubDebounce;
  Timer? _pollingTimer;
  bool _inFlight = false;

  RequestFilterType _currentFilter = RequestFilterType.all;
  int _currentPage = 1;
  static const int _pageSize = 10;

  IncomingRequestsCubit(this._getRequests)
      : super(const IncomingRequestsInitial()) {
    _hubService = sl<BookingTrackingHubService>();
    _listenToHub();
  }

  void _listenToHub() {
    _hubSub?.cancel();
    _hubSub = _hubService.requestStream.listen((_) {
      // Silently refresh when new request comes in
      _hubDebounce?.cancel();
      _hubDebounce = Timer(const Duration(milliseconds: 900), () {
        if (isClosed) return;
        load(silent: true);
      });
    });

    // Production-grade polling fallback (every 30s)
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      // Only refresh if we are not already loading and we have a loaded state
      if (!_inFlight && (state is IncomingRequestsLoaded || state is IncomingRequestsEmpty)) {
        debugPrint('🔄 [IncomingRequestsCubit] Auto-refreshing requests...');
        load(silent: true);
      }
    });
  }

  /// Load first page with optional filter
  Future<void> load({
    RequestFilterType? filter,
    bool silent = false,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    if (filter != null) {
      _currentFilter = filter;
    }
    _currentPage = 1;

    if (!silent) emit(const IncomingRequestsLoading());

    try {
      final response = await _getRequests(
        type: _currentFilter.apiValue,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (isClosed) return;

      if (response.items.isEmpty) {
        emit(IncomingRequestsEmpty(_currentFilter));
      } else {
        emit(IncomingRequestsLoaded(
          requests: response.items,
          filter: _currentFilter,
          currentPage: _currentPage,
          hasNextPage: response.hasNextPage,
          totalCount: response.totalCount,
        ));
      }
    } catch (e) {
      if (isClosed) return;
      emit(IncomingRequestsError(e.toString(), _currentFilter));
    } finally {
      _inFlight = false;
    }
  }

  /// Load next page (infinite scroll)
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! IncomingRequestsLoaded) return;
    if (!currentState.hasNextPage) return;

    emit(IncomingRequestsLoadingMore(
      currentState.requests,
      currentState.filter,
    ));

    _currentPage++;

    try {
      final response = await _getRequests(
        type: _currentFilter.apiValue,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (isClosed) return;

      final updatedRequests = [
        ...currentState.requests,
        ...response.items,
      ];

      emit(IncomingRequestsLoaded(
        requests: updatedRequests,
        filter: _currentFilter,
        currentPage: _currentPage,
        hasNextPage: response.hasNextPage,
        totalCount: response.totalCount,
      ));
    } catch (e) {
      if (isClosed) return;
      // On error, revert to previous state
      emit(currentState);
    }
  }

  /// Change filter and reload
  Future<void> changeFilter(RequestFilterType filter) async {
    if (_currentFilter == filter) return;
    await load(filter: filter);
  }

  /// Refresh current view
  Future<void> refresh() async {
    await load(filter: _currentFilter);
  }

  @override
  Future<void> close() {
    _hubDebounce?.cancel();
    _pollingTimer?.cancel();
    _hubSub?.cancel();
    return super.close();
  }
}

