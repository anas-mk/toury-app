import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/features/tourist/features/profile/cubit/profile_cubit/profile_state.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

// Use AuthRepository instead of SharedPreferences directly
class ProfileCubit extends Cubit<ProfileState> {
  final AuthRepository authRepository;

  ProfileCubit(this.authRepository) : super(ProfileLoading());

  Future<void> loadUser() async {
    emit(ProfileLoading());

    try {
      final result = await authRepository.getCachedUser();

      result.fold(
            (failure) => emit(ProfileError(failure.message)),
            (user) {
          if (user != null) {
            emit(ProfileLoaded(user));
          } else {
            emit(ProfileError("No user data found"));
          }
        },
      );
    } catch (e) {
      emit(ProfileError("Failed to load user: ${e.toString()}"));
    }
  }

  // Add refresh method
  Future<void> refreshUser() async {
    await loadUser();
  }
}