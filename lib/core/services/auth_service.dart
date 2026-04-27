import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SharedPreferences _prefs;

  AuthService(this._prefs);

  static const String _tokenKey = 'token';
  static const String _roleKey = 'role';

  final StreamController<String> _tokenChanges =
      StreamController<String>.broadcast();

  /// Emits whenever [saveToken] persists a new value (used to restart SignalR
  /// with the latest access string without waiting for a transport drop).
  Stream<String> get authTokenChanges => _tokenChanges.stream;

  Future<void> saveToken(String token) async {
    final prev = _prefs.getString(_tokenKey);
    await _prefs.setString(_tokenKey, token);
    if (prev != token) {
      _tokenChanges.add(token);
    }
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
