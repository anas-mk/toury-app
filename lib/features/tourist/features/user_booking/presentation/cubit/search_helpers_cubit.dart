import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_entity.dart';
import 'dart:async';
import '../../domain/usecases/search_scheduled_helpers_usecase.dart';
import '../../domain/usecases/search_instant_helpers_usecase.dart';
import '../../../maps/presentation/cubit/map_cubit.dart';
import '../../../maps/presentation/cubit/map_state.dart';

abstract class SearchHelpersState {}
class SearchHelpersInitial extends SearchHelpersState {}
class SearchHelpersLoading extends SearchHelpersState {}
class SearchHelpersSuccess extends SearchHelpersState {
  final List<HelperEntity> helpers;
  SearchHelpersSuccess(this.helpers);
}
class SearchHelpersError extends SearchHelpersState {
  final String message;
  SearchHelpersError(this.message);
}

class SearchHelpersCubit extends Cubit<SearchHelpersState> {
  final SearchScheduledHelpersUseCase searchScheduled;
  final SearchInstantHelpersUseCase searchInstant;
  final MapCubit mapCubit;
  StreamSubscription? _mapSubscription;

  SearchHelpersCubit({
    required this.searchScheduled,
    required this.searchInstant,
    required this.mapCubit,
  }) : super(SearchHelpersInitial()) {
    _mapSubscription = mapCubit.stream.listen((mapState) {
      if (mapState is LocationSelected) {
        searchInstantHelpers(
          pickupLocation: mapState.location.address,
          lat: mapState.location.lat,
          lng: mapState.location.lng,
        );
      }
    });
  }

  @override
  Future<void> close() {
    _mapSubscription?.cancel();
    return super.close();
  }

  Future<void> searchScheduledHelpers({
    required String destination,
    required DateTime date,
    required String language,
    required bool needArabic,
    required int durationInMinutes,
  }) async {
    emit(SearchHelpersLoading());
    final result = await searchScheduled(SearchScheduledHelpersParams(
      destination: destination,
      date: date,
      language: language,
      needArabic: needArabic,
      durationInMinutes: durationInMinutes,
    ));
    result.fold(
      (failure) => emit(SearchHelpersError(failure.message)),
      (helpers) => emit(SearchHelpersSuccess(helpers)),
    );
  }

  Future<void> searchInstantHelpers({
    required String pickupLocation,
    required double lat,
    required double lng,
  }) async {
    emit(SearchHelpersLoading());
    final result = await searchInstant(SearchInstantHelpersParams(
      pickupLocation: pickupLocation,
      lat: lat,
      lng: lng,
    ));
    result.fold(
      (failure) => emit(SearchHelpersError(failure.message)),
      (helpers) => emit(SearchHelpersSuccess(helpers)),
    );
  }
}
