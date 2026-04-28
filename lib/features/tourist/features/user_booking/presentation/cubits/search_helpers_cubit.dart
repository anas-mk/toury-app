import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/search_helpers_usecase.dart';
import '../../domain/entities/search_params.dart';
import '../../../../../../../../core/services/location_cubit_impl.dart';
import 'search_helpers_state.dart';

class SearchHelpersCubit extends Cubit<SearchHelpersState> {
  final SearchScheduledHelpersUseCase searchScheduledHelpersUseCase;
  final SearchInstantHelpersUseCase searchInstantHelpersUseCase;
  final LocationCubit locationCubit;

  Timer? _debounce;
  // Track the last request params to avoid duplicate calls
  Object? _lastSearchKey;

  static const _debounceDuration = Duration(milliseconds: 400);

  SearchHelpersCubit({
    required this.searchScheduledHelpersUseCase,
    required this.searchInstantHelpersUseCase,
    required this.locationCubit,
  }) : super(SearchHelpersInitial());

  // ─── Scheduled Search ──────────────────────────────────────────────────────

  void scheduleScheduledSearch(ScheduledSearchParams params) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => searchScheduled(params));
  }

  Future<void> searchScheduled(ScheduledSearchParams params) async {
    // Scheduled search does NOT require live location, only city name
    if (params.destinationCity.trim().isEmpty) {
      emit(const SearchHelpersError('Please enter a destination city.'));
      return;
    }

    // Deduplication
    final key = params.props;
    if (_lastSearchKey == key && state is SearchHelpersLoaded) return;
    _lastSearchKey = key;

    if (isClosed) return;
    emit(SearchHelpersLoading());

    debugPrint(
      '[SearchHelpersCubit] Scheduled search request:\n'
      '  city: ${params.destinationCity}\n'
      '  date: ${params.requestedDate}\n'
      '  startTime: ${params.startTime}\n'
      '  duration: ${params.durationInMinutes} min\n'
      '  language: ${params.requestedLanguage}\n'
      '  requiresCar: ${params.requiresCar}\n'
      '  travelersCount: ${params.travelersCount}',
    );

    final result = await searchScheduledHelpersUseCase(params);
    if (isClosed) return;

    result.fold(
      (failure) => emit(SearchHelpersError(failure.message)),
      (helpers) {
        debugPrint('[SearchHelpersCubit] Scheduled search returned ${helpers.length} helpers.');
        emit(SearchHelpersLoaded(helpers));
      },
    );
  }

  // ─── Instant Search ────────────────────────────────────────────────────────

  void scheduleInstantSearch(InstantSearchParams params) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => searchInstant(params));
  }

  /// Resolves the real GPS location, validates it, then calls the API.
  Future<void> searchInstant(InstantSearchParams params) async {
    if (isClosed) return;

    // 1. Validate / resolve coordinates
    final coords = await _resolveCoordinates(
      providedLat: params.pickupLatitude,
      providedLng: params.pickupLongitude,
    );

    if (coords == null) {
      // _resolveCoordinates already emitted an appropriate error state
      return;
    }

    // 2. Build final params with real coordinates
    final resolvedParams = InstantSearchParams(
      pickupLocationName: params.pickupLocationName,
      pickupLatitude: coords.$1,
      pickupLongitude: coords.$2,
      durationInMinutes: params.durationInMinutes,
      requestedLanguage: params.requestedLanguage,
      requiresCar: params.requiresCar,
      travelersCount: params.travelersCount,
    );

    // 3. Deduplication
    final key = resolvedParams.props;
    if (_lastSearchKey == key && state is SearchHelpersLoaded) return;
    _lastSearchKey = key;

    if (isClosed) return;
    emit(SearchHelpersLoading());

    debugPrint(
      '[SearchHelpersCubit] Instant search request:\n'
      '  pickup: ${resolvedParams.pickupLocationName}\n'
      '  lat: ${resolvedParams.pickupLatitude}\n'
      '  lng: ${resolvedParams.pickupLongitude}\n'
      '  duration: ${resolvedParams.durationInMinutes} min\n'
      '  language: ${resolvedParams.requestedLanguage}\n'
      '  requiresCar: ${resolvedParams.requiresCar}\n'
      '  travelersCount: ${resolvedParams.travelersCount}',
    );

    final result = await searchInstantHelpersUseCase(resolvedParams);
    if (isClosed) return;

    result.fold(
      (failure) => emit(SearchHelpersError(failure.message)),
      (helpers) {
        debugPrint('[SearchHelpersCubit] Instant search returned ${helpers.length} helpers.');
        emit(SearchHelpersLoaded(helpers));
      },
    );
  }

  // ─── Internal helpers ──────────────────────────────────────────────────────

  /// Returns real (lat, lng) — either the provided values (if valid) or
  /// fetched from GPS. Emits error states and returns null if unavailable.
  Future<(double, double)?> _resolveCoordinates({
    required double providedLat,
    required double providedLng,
  }) async {
    // If valid non-zero coordinates were provided, use them directly
    if (_isValidCoord(providedLat, providedLng)) {
      return (providedLat, providedLng);
    }

    // Otherwise, get real location from GPS
    debugPrint('[SearchHelpersCubit] Coordinates not provided — fetching GPS location…');

    if (isClosed) return null;
    emit(const SearchHelpersError('Fetching your location…', isLocating: true));

    await locationCubit.fetchLocation();
    final locState = locationCubit.state;

    if (locState is LocationReady) {
      debugPrint(
        '[SearchHelpersCubit] GPS resolved: lat=${locState.latitude}, '
        'lng=${locState.longitude}',
      );
      return (locState.latitude, locState.longitude);
    }

    if (!isClosed) {
      if (locState is LocationPermissionDeniedState) {
        emit(const SearchHelpersError(
          'Location permission denied. Please allow location access and try again.',
        ));
      } else if (locState is LocationPermissionPermanentlyDeniedState) {
        emit(const SearchHelpersError(
          'Location permission is permanently denied. Open app settings to enable it.',
          isPermissionPermanentlyDenied: true,
        ));
      } else if (locState is LocationServiceDisabledState) {
        emit(const SearchHelpersError(
          'GPS is turned off. Please enable location services and try again.',
          isServiceDisabled: true,
        ));
      } else {
        emit(const SearchHelpersError(
          'Could not determine your location. Please try again.',
        ));
      }
    }
    return null;
  }

  bool _isValidCoord(double lat, double lng) =>
      !(lat == 0.0 && lng == 0.0) &&
      lat >= -90 && lat <= 90 &&
      lng >= -180 && lng <= 180;

  void clearSearch() {
    _debounce?.cancel();
    _lastSearchKey = null;
    emit(SearchHelpersInitial());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
