import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationCubit extends Cubit<Locale> {
  LocalizationCubit() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('locale') ?? 'en';
    emit(Locale(savedLocale));
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', languageCode);
    emit(Locale(languageCode));
  }

  Future<void> changeLocale(String languageCode) async {
    await setLanguage(languageCode);
  }

  Future<void> toggleLanguage() async {
    final newLocale = state.languageCode == 'en' ? 'ar' : 'en';
    await setLanguage(newLocale);
  }
}
