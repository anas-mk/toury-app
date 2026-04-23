import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SharedPreferences _prefs;

  AuthService(this._prefs);

  static const String _tokenKey = 'token';
  static const String _roleKey = 'role';

  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<void> saveRole(String role) async {
    await _prefs.setString(_roleKey, role);
  }

  String? getRole() {
    return _prefs.getString(_roleKey);
  }

  Future<void> clearAuth() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_roleKey);
  }
}
