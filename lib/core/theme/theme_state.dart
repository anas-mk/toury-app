import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AppThemeMode { system, light, dark }

class ThemeState extends Equatable {
  final AppThemeMode mode;

  const ThemeState({required this.mode});

  ThemeMode get themeMode {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  ThemeState copyWith({AppThemeMode? mode}) {
    return ThemeState(mode: mode ?? this.mode);
  }

  static AppThemeMode fromStored(
    String? raw, {
    required AppThemeMode fallback,
  }) {
    if (raw == null) return fallback;
    return AppThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => fallback,
    );
  }

  @override
  List<Object> get props => [mode];
}
