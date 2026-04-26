import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/search_helpers_usecase.dart';
import '../../domain/entities/search_params.dart';
import 'search_helpers_state.dart';

class SearchHelpersCubit extends Cubit<SearchHelpersState> {
  final SearchScheduledHelpersUseCase searchScheduledHelpersUseCase;
  final SearchInstantHelpersUseCase searchInstantHelpersUseCase;

  SearchHelpersCubit({
    required this.searchScheduledHelpersUseCase,
    required this.searchInstantHelpersUseCase,
  }) : super(SearchHelpersInitial());

  Future<void> searchScheduled(ScheduledSearchParams params) async {
    emit(SearchHelpersLoading());
    final result = await searchScheduledHelpersUseCase(params);
    result.fold(
      (failure) => emit(SearchHelpersError(failure.message)),
      (helpers) => emit(SearchHelpersLoaded(helpers)),
    );
  }

  Future<void> searchInstant(InstantSearchParams params) async {
    emit(SearchHelpersLoading());
    final result = await searchInstantHelpersUseCase(params);
    result.fold(
      (failure) => emit(SearchHelpersError(failure.message)),
      (helpers) => emit(SearchHelpersLoaded(helpers)),
    );
  }

  void clearSearch() {
    emit(SearchHelpersInitial());
  }
}
