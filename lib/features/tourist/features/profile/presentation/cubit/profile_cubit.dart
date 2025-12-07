import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/features/tourist/features/profile/presentation/cubit/profile_state.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

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
            emit(const ProfileError("No user data found"));
          }
        },
      );
    } catch (e) {
      emit(ProfileError("Failed to load user: ${e.toString()}"));
    }
  }

  // ✅ Update Profile Method with Image Upload
  Future<void> updateProfile({
    required String userName,
    required String userId,
    required String phoneNumber,
    required String gender,
    required DateTime birthDate,
    required String country,
    File? profileImage,
  }) async {
    emit(ProfileUpdating());

    try {
      final result = await authRepository.updateProfile(
        userName: userName,
        userId: userId,
        phoneNumber: phoneNumber,
        gender: gender,
        birthDate: birthDate,
        country: country,
        profileImage: profileImage,
      );

      result.fold(
            (failure) => emit(ProfileError(failure.message)),
            (updatedUser) {
          emit(ProfileUpdateSuccess(updatedUser));
          // Reload the updated user
          emit(ProfileLoaded(updatedUser));
        },
      );
    } catch (e) {
      emit(ProfileError("Failed to update profile: ${e.toString()}"));
    }
  }

  // Refresh method
  Future<void> refreshUser() async {
    await loadUser();
  }
}