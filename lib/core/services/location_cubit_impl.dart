import 'package:flutter_bloc/flutter_bloc.dart';
import 'location_service.dart';
import 'location_cubit.dart';

export 'location_cubit.dart';

class LocationCubit extends Cubit<LocationState> {
  final LocationService _locationService;

  LocationCubit({LocationService? locationService})
      : _locationService = locationService ?? LocationService(),
        super(LocationInitial());

  /// Fetches location once and caches it in state.
  /// Subsequent calls return the cached result immediately
  /// unless [forceRefresh] is true.
  Future<void> fetchLocation({bool forceRefresh = false}) async {
    if (!forceRefresh && state is LocationReady) return;

    if (isClosed) return;
    emit(LocationLoading());

    final result = await _locationService.getCurrentLocation();

    if (isClosed) return;

    switch (result) {
      case LocationSuccess():
        emit(LocationReady(
          latitude: result.latitude,
          longitude: result.longitude,
          accuracy: result.accuracy,
        ));
      case LocationPermissionDenied():
        emit(LocationPermissionDeniedState());
      case LocationPermissionPermanentlyDenied():
        emit(LocationPermissionPermanentlyDeniedState());
      case LocationServiceDisabled():
        emit(LocationServiceDisabledState());
      case LocationError():
        emit(LocationErrorState(result.message));
    }
  }

  /// Returns coordinates if already available, otherwise fetches.
  /// Convenience helper for cubits that need to gate on location.
  Future<({double lat, double lng})?> requireLocation() async {
    if (state is! LocationReady) {
      await fetchLocation();
    }
    final current = state;
    if (current is LocationReady) {
      return (lat: current.latitude, lng: current.longitude);
    }
    return null;
  }
}
