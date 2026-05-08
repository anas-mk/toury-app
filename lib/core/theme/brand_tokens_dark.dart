// lib/core/theme/brand_tokens_dark.dart
//
// Dark-mode counterparts to BrandTokens. Pure black is too harsh for
// long-form reading and too saturated against the brand blue, so we use
// a tinted near-black surface system aligned with #0F1117 (Slate-Black).
//
// IMPORTANT: only colors meant to flip in dark mode live here. Brand
// gradients and accent colors stay identical to keep the brand identity
// consistent across both themes.

import 'package:flutter/widgets.dart';

abstract class BrandTokensDark {
  BrandTokensDark._();

  // ── Surface stack ─────────────────────────────────────────────────
  /// Scaffold background — slightly lighter than pure black to preserve
  /// shadow layering in dark mode.
  static const Color bgScaffold = Color(0xFF0B0E16);

  /// Default card / surface — one stop lighter than scaffold.
  static const Color surface = Color(0xFF141826);

  /// Elevated surface — sheets, dialogs, modal headers.
  static const Color surfaceElevated = Color(0xFF1B2030);

  /// Subtle inset surface — search bars on dark backgrounds.
  static const Color surfaceInset = Color(0xFF0F1320);

  // ── Borders ────────────────────────────────────────────────────────
  static const Color borderSoft = Color(0xFF222A3D);
  static const Color borderTinted = Color(0xFF2A3554);

  // ── Text ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF1F4FB);
  static const Color textSecondary = Color(0xFFA9B1C6);
  static const Color textMuted = Color(0xFF6B7592);

  // ── Brand (slightly lifted for dark contrast) ──────────────────────
  /// Brand navy lifts to a readable sky-blue on dark surfaces (pairs with
  /// light-mode `#0B3D91`).
  static const Color primaryBlue = Color(0xFF6CB6FF);
  static const Color primaryBlueDark = Color(0xFF4A9FE8);

  /// Tinted background for primary chips/buttons in dark mode.
  static const Color primaryBlueSoft = Color(0xFF132F4A);

  // ── Status surfaces ────────────────────────────────────────────────
  static const Color successGreenSoft = Color(0xFF103324);
  static const Color dangerRedSoft = Color(0xFF3A1418);
  static const Color accentAmberSoft = Color(0xFF3A2A0F);
  static const Color accentAmberText = Color(0xFFFCD34D);

  // ── Shadow tints ───────────────────────────────────────────────────
  /// Shadows in dark mode are nearly invisible — we still apply a tiny
  /// lift to give cards a sense of float above the scaffold.
  static const Color shadowSoft = Color(0x33000000);
  static const Color shadowDeep = Color(0x4D000000);
}
