// lib/core/theme/app_color.dart
//
// Color access for the entire app.
//
// `AppColor.*` static constants are kept for backward compatibility (40+
// existing call sites). They always resolve to the LIGHT variants of
// each token — this matches the previous behaviour exactly.
//
// New code should prefer `AppColors.of(context)` (theme-aware) so the
// same widget renders correctly under both light and dark mode without
// branching on `Theme.of(context).brightness` everywhere.

import 'package:flutter/material.dart';

import 'brand_tokens.dart';
import 'brand_tokens_dark.dart';

// ════════════════════════════════════════════════════════════════════
// Backward-compatible static API. KEEP THESE NAMES — they are imported
// by ~50 existing files. Each constant resolves to the LIGHT variant.
// ════════════════════════════════════════════════════════════════════
class AppColor {
  AppColor._();

  // ── Primary ───────────────────────────────────────────────────────
  static const Color primaryColor = BrandTokens.primaryBlue;
  static const Color darkPrimary = BrandTokens.primaryBlueDark;

  // ── Secondary / accent ────────────────────────────────────────────
  static const Color secondaryColor = BrandTokens.primaryBlue;

  // ── Backgrounds ───────────────────────────────────────────────────
  static const Color lightBackground = BrandTokens.bgSoft;
  static const Color darkBackground = BrandTokensDark.bgScaffold;
  static const Color lightSurface = BrandTokens.surfaceWhite;
  static const Color darkSurface = BrandTokensDark.surface;

  // ── Text ──────────────────────────────────────────────────────────
  static const Color lightText = BrandTokens.textPrimary;
  static const Color darkText = BrandTokensDark.textPrimary;
  static const Color lightTextSecondary = BrandTokens.textSecondary;
  static const Color darkTextSecondary = BrandTokensDark.textSecondary;

  // ── Status / accents ──────────────────────────────────────────────
  static const Color accentColor = BrandTokens.successGreen;
  static const Color errorColor = BrandTokens.dangerSos;
  static const Color warningColor = BrandTokens.warningAmber;

  // ── Cards ─────────────────────────────────────────────────────────
  static const Color lightCardColor = BrandTokens.surfaceWhite;
  static const Color darkCardColor = BrandTokensDark.surface;

  // ── Borders ───────────────────────────────────────────────────────
  static const Color lightBorder = BrandTokens.borderSoft;
  static const Color darkBorder = BrandTokensDark.borderSoft;

  // ── Misc legacy names ─────────────────────────────────────────────
  static const Color routeColor = BrandTokens.primaryBlue;
  static const Color destinationColor = BrandTokens.dangerSos;
}

// ════════════════════════════════════════════════════════════════════
// Theme-aware semantic palette. Use `AppColors.of(context).primary` so
// pages flip with dark mode without manual branching.
// ════════════════════════════════════════════════════════════════════

/// Semantic palette resolved against the active [ThemeData.brightness].
///
/// Hold the result of [AppColors.of] in a local variable when you need
/// to reference more than one token in a build method — it avoids
/// re-resolving `Theme.of(context)` for every getter access.
class AppColors {
  final Brightness brightness;

  const AppColors._(this.brightness);

  factory AppColors.of(BuildContext context) {
    return AppColors._(Theme.of(context).brightness);
  }

  bool get isDark => brightness == Brightness.dark;

  // ── Brand ─────────────────────────────────────────────────────────
  Color get primary =>
      isDark ? BrandTokensDark.primaryBlue : BrandTokens.primaryBlue;
  Color get primaryStrong =>
      isDark ? BrandTokensDark.primaryBlueDark : BrandTokens.primaryBlueDark;
  Color get primarySoft =>
      isDark ? BrandTokensDark.primaryBlueSoft : const Color(0xFFE3EDF7);
  Color get onPrimary => Colors.white;

  Color get accent => BrandTokens.accentAmber;
  Color get accentSoft =>
      isDark ? BrandTokensDark.accentAmberSoft : BrandTokens.accentAmberSoft;
  Color get accentText =>
      isDark ? BrandTokensDark.accentAmberText : BrandTokens.accentAmberText;
  Color get onAccent => Colors.white;

  // ── Surfaces ──────────────────────────────────────────────────────
  /// Page scaffold background.
  Color get scaffold =>
      isDark ? BrandTokensDark.bgScaffold : BrandTokens.bgSoft;

  /// Default raised surface (cards, app bars on light).
  Color get surface =>
      isDark ? BrandTokensDark.surface : BrandTokens.surfaceWhite;

  /// One stop higher than [surface] — sheets/dialogs/tooltips.
  Color get surfaceElevated =>
      isDark ? BrandTokensDark.surfaceElevated : BrandTokens.surfaceWhite;

  /// Subtle inset surface used for search bars, code blocks.
  Color get surfaceInset =>
      isDark ? BrandTokensDark.surfaceInset : BrandTokens.bgSoft;

  // ── Borders ───────────────────────────────────────────────────────
  Color get border =>
      isDark ? BrandTokensDark.borderSoft : BrandTokens.borderSoft;
  Color get borderTinted =>
      isDark ? BrandTokensDark.borderTinted : BrandTokens.borderTinted;

  // ── Text ──────────────────────────────────────────────────────────
  Color get textPrimary =>
      isDark ? BrandTokensDark.textPrimary : BrandTokens.textPrimary;
  Color get textSecondary =>
      isDark ? BrandTokensDark.textSecondary : BrandTokens.textSecondary;
  Color get textMuted =>
      isDark ? BrandTokensDark.textMuted : BrandTokens.textMuted;
  Color get textInverse =>
      isDark ? BrandTokens.textPrimary : BrandTokensDark.textPrimary;

  // ── Status ────────────────────────────────────────────────────────
  Color get success => BrandTokens.successGreen;
  Color get successSoft =>
      isDark ? BrandTokensDark.successGreenSoft : BrandTokens.successGreenSoft;
  Color get danger => BrandTokens.dangerSos;
  Color get dangerSoft =>
      isDark ? BrandTokensDark.dangerRedSoft : BrandTokens.dangerRedSoft;
  Color get warning => BrandTokens.warningAmber;
  Color get warningSoft =>
      isDark ? BrandTokensDark.accentAmberSoft : BrandTokens.accentAmberSoft;
  Color get info => primary;
  Color get infoSoft => primarySoft;

  /// Dim overlay used when a screen is loading or behind a modal.
  Color get scrim =>
      isDark ? const Color(0xCC000000) : const Color(0x66000000);

  /// Color for divider lines.
  Color get divider => border;

  // ── Action / interactive states ───────────────────────────────────
  Color get onSurfaceMuted => textSecondary;
  Color get disabledFill => isDark
      ? BrandTokensDark.borderSoft.withValues(alpha: 0.6)
      : BrandTokens.borderSoft;
  Color get disabledText => textMuted;
}
