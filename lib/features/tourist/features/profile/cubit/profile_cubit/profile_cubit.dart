import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toury/features/tourist/features/profile/cubit/profile_cubit/profile_state.dart';
import '../../../auth/data/models/user_model.dart';


class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileLoading());

  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson == null) {
        emit(ProfileError("No user data found"));
        return;
      }
      final user = UserModel.fromJson(jsonDecode(userJson));
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError("Failed to load user"));
    }
  }
}
