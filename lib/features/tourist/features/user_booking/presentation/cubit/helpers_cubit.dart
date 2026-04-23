import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_entity.dart';
import '../../domain/usecases/get_helper_profile_usecase.dart';
import '../../domain/usecases/get_alternatives_usecase.dart';
import '../../domain/entities/alternative_helper_entity.dart';

abstract class HelpersState {}
class HelpersInitial extends HelpersState {}
class HelpersLoading extends HelpersState {}
class HelperProfileSuccess extends HelpersState {
  final HelperEntity helper;
  HelperProfileSuccess(this.helper);
}
class AlternativesSuccess extends HelpersState {
  final List<AlternativeHelperEntity> alternatives;
  AlternativesSuccess(this.alternatives);
}
class HelpersError extends HelpersState {
  final String message;
  HelpersError(this.message);
}

class HelpersCubit extends Cubit<HelpersState> {
  final GetHelperProfileUseCase getProfile;
  final GetAlternativesUseCase getAlternativesUseCase;

  HelpersCubit({
    required this.getProfile,
    required this.getAlternativesUseCase,
  }) : super(HelpersInitial());

  Future<void> loadProfile(String helperId) async {
    emit(HelpersLoading());
    final result = await getProfile(helperId);
    result.fold(
      (failure) => emit(HelpersError(failure.message)),
      (helper) => emit(HelperProfileSuccess(helper)),
    );
  }

  Future<void> loadAlternatives(String bookingId) async {
    emit(HelpersLoading());
    final result = await getAlternativesUseCase(bookingId);
    result.fold(
      (failure) => emit(HelpersError(failure.message)),
      (alts) => emit(AlternativesSuccess(alts)),
    );
  }
}
