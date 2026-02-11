import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../../domain/entities/location.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_route.dart';
import 'map_state.dart';

/// Map Cubit - إدارة حالة الخريطة
class MapCubit extends Cubit<MapState> {
  final GetCurrentLocation getCurrentLocation;
  final GetRoute getRoute;

  Location? _currentLocation;

  MapCubit({
    required this.getCurrentLocation,
    required this.getRoute,
  }) : super(MapInitial());

  /// الحصول على الموقع الحالي
  Future<void> loadCurrentLocation() async {
    emit(MapLoading());

    final result = await getCurrentLocation(NoParams());

    result.fold(
          (failure) => emit(MapError(failure.message)),
          (location) {
        _currentLocation = location;
        emit(LocationLoaded(location));
      },
    );
  }

  /// الحصول على المسار إلى الوجهة
  Future<void> loadRoute(Location destination) async {
    if (_currentLocation == null) {
      emit(const MapError('Current location not available'));
      return;
    }

    emit(MapLoading());

    final result = await getRoute(RouteParams(
      start: _currentLocation!,
      destination: destination,
    ));

    result.fold(
          (failure) => emit(MapError(failure.message)),
          (route) => emit(RouteLoaded(
        currentLocation: _currentLocation!,
        route: route,
      )),
    );
  }

  /// إلغاء المسار
  void clearRoute() {
    if (_currentLocation != null) {
      emit(RouteCleared(_currentLocation!));
    }
  }

  /// الحصول على الموقع الحالي (للاستخدام الداخلي)
  Location? get currentLocation => _currentLocation;
}