import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/helper_model.dart';

abstract class HelperLocalDataSource {
  Future<void> cacheHelper(HelperModel helper);
  Future<HelperModel?> getCurrentHelper();
  Future<void> clearHelper();
}

class HelperLocalDataSourceImpl implements HelperLocalDataSource {
  @override
  Future<void> cacheHelper(HelperModel helper) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('helper', jsonEncode(helper.toJson()));
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
  }
}
