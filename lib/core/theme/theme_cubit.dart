// lib/core/theme/theme_cubit.dart
//
// Manages the app's [ThemeMode] preference. Supports three modes:
//   - [ThemeMode.system]  → follows the OS appearance setting
//   - [ThemeMode.light]
//   - [ThemeMode.dark]
//
// Persisted via SharedPreferences with the key `theme_mode_v2`. The legacy
// boolean `isDark` key is still read on first run to migrate existing
// users without losing their preference.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const _legacyKey = 'isDark';
  static const _key = 'theme_mode_v2';

  ThemeCubit({bool? isDark})
    : super(
        ThemeState(
          mode: (isDark ?? false) ? AppThemeMode.dark : AppThemeMode.light,
        ),
      ) {
    _hydrate();
  }

  /// Re-read the persisted mode from SharedPreferences. Falls back to the
  /// legacy boolean `isDark` flag when the new key is missing.
  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_key);
      if (stored != null) {
        final parsed = ThemeState.fromStored(stored, fallback: state.mode);
        if (parsed != state.mode) {
          emit(state.copyWith(mode: parsed));
        }
        return;
      }
      // Migrate from legacy `isDark` boolean.
      final legacyDark = prefs.getBool(_legacyKey);
      if (legacyDark != null) {
        emit(
          state.copyWith(
            mode: legacyDark ? AppThemeMode.dark : AppThemeMode.light,
          ),
        );
      }
    } catch (_) {
      // Persistence is best-effort — never break the app for it.
    }
  }

  Future<void> _persist(AppThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
      // Keep legacy flag in sync for any other readers still using it.
      if (mode != AppThemeMode.system) {
        await prefs.setBool(_legacyKey, mode == AppThemeMode.dark);
      }
    } catch (_) {
      // Silently drop — UI state is already updated.
    }
  }

  /// Cycle through the three modes (system → light → dark → system).
  Future<void> toggleTheme() async {
    final next = switch (state.mode) {
      AppThemeMode.system => AppThemeMode.light,
      AppThemeMode.light => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.system,
    };
    emit(state.copyWith(mode: next));
    await _persist(next);
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == state.mode) return;
    emit(state.copyWith(mode: mode));
    await _persist(mode);
  }

  Future<void> useLight() => setMode(AppThemeMode.light);
  Future<void> useDark() => setMode(AppThemeMode.dark);
  Future<void> useSystem() => setMode(AppThemeMode.system);
}
