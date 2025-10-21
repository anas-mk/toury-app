import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({required bool isDark})
      : super(isDark ? ThemeMode.dark : ThemeMode.light);

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = state == ThemeMode.dark;
    await prefs.setBool('isDark', !isDark);
    emit(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
