import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/search_locations.dart';
import 'search_location_state.dart';

/// Search Location Cubit - إدارة حالة البحث عن الأماكن
class SearchLocationCubit extends Cubit<SearchLocationState> {
  final SearchLocations searchLocations;
  Timer? _debounceTimer;

  SearchLocationCubit({required this.searchLocations})
      : super(SearchLocationInitial());

  /// البحث عن أماكن مع debounce
  void search(String query) {
    // إلغاء التايمر السابق
    _debounceTimer?.cancel();

    // إذا كان النص فارغ
    if (query.trim().isEmpty) {
      emit(SearchLocationInitial());
      return;
    }

    // إنشاء تايمر جديد
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _performSearch(query.trim());
    });
  }

  /// تنفيذ البحث
  Future<void> _performSearch(String query) async {
    emit(SearchLocationLoading());

    final result = await searchLocations(SearchParams(query: query));

    result.fold(
          (failure) => emit(SearchLocationError(failure.message)),
          (locations) {
        if (locations.isEmpty) {
          emit(SearchLocationEmpty(query));
        } else {
          emit(SearchLocationLoaded(locations));
        }
      },
    );
  }

  /// مسح البحث
  void clear() {
    _debounceTimer?.cancel();
    emit(SearchLocationInitial());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}