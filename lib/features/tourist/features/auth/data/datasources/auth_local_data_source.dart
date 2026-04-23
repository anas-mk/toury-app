import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../core/services/auth_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCurrentUser();
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final AuthService authService;

  AuthLocalDataSourceImpl(this.authService);

  @override
  Future<void> cacheUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
    if (user.token != null) {
      await authService.saveToken(user.token!);
    }
    await authService.saveRole('tourist');
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return null;
    final Map<String, dynamic> data = jsonDecode(userJson);
    return UserModel.fromJson(data);
  }

  @override
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await authService.clearAuth();
  }
}