import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../core/services/auth_service.dart';
import '../models/helper_model.dart';

abstract class HelperLocalDataSource {
  Future<void> cacheHelper(HelperModel helper);
  Future<HelperModel?> getCurrentHelper();
  Future<void> clearHelper();
}

class HelperLocalDataSourceImpl implements HelperLocalDataSource {
  final AuthService authService;

  HelperLocalDataSourceImpl(this.authService);

  @override
  Future<void> cacheHelper(HelperModel helper) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('helper', jsonEncode(helper.toJson()));
    if (helper.token != null) {
      await authService.saveToken(helper.token!);
    }
    await authService.saveRole('helper');
  }

  @override
  Future<HelperModel?> getCurrentHelper() async {
    final prefs = await SharedPreferences.getInstance();
    final helperJson = prefs.getString('helper');
    if (helperJson == null) return null;
    final Map<String, dynamic> data = jsonDecode(helperJson);
    return HelperModel.fromJson(data);
  }

  @override
  Future<void> clearHelper() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('helper');
    await authService.clearAuth();
  }
}
