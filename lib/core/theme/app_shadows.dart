// lib/core/theme/app_shadows.dart
//
// Theme-aware shadow helpers. In light mode shadows use the brand-tinted
// shadow tokens (so cards look like they're lifting on warm paper). In
// dark mode shadows are reduced to a faint black layer and replaced
// largely by border highlight to retain depth without grey halos.

import 'package:flutter/material.dart';

import 'brand_tokens.dart';
import 'brand_tokens_dark.dart';

abstract class AppShadows {
  AppShadows._();

  // ── Light mode shadows ────────────────────────────────────────────

  static const List<BoxShadow> _lightSm = [
    BoxShadow(
      color: BrandTokens.shadowSoft,
      blurRadius: 12,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> _lightMd = [
    BoxShadow(
      color: BrandTokens.shadowSoft,
      blurRadius: 24,
      spreadRadius: -6,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> _lightLg = [
    BoxShadow(
      color: BrandTokens.shadowSoft,
      blurRadius: 32,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: BrandTokens.shadowSoft,
      blurRadius: 8,
      spreadRadius: -2,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> _lightXl = [
    BoxShadow(
      color: BrandTokens.shadowDeep,
      blurRadius: 48,
      spreadRadius: -12,
      offset: Offset(0, 24),
    ),
  ];

  // ── Dark mode shadows (subtle) ────────────────────────────────────

  static const List<BoxShadow> _darkSm = [
    BoxShadow(
      color: BrandTokensDark.shadowSoft,
      blurRadius: 12,
      spreadRadius: -3,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> _darkMd = [
    BoxShadow(
      color: BrandTokensDark.shadowSoft,
      blurRadius: 22,
      spreadRadius: -8,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> _darkLg = [
    BoxShadow(
      color: BrandTokensDark.shadowDeep,
      blurRadius: 32,
      spreadRadius: -10,
      offset: Offset(0, 14),
    ),
  ];

  static const List<BoxShadow> _darkXl = [
    BoxShadow(
      color: BrandTokensDark.shadowDeep,
      blurRadius: 48,
      spreadRadius: -14,
      offset: Offset(0, 24),
    ),
  ];

  /// Theme-aware tiny lift (e.g. small chips).
  static List<BoxShadow> sm(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkSm : _lightSm;

  /// Theme-aware standard card shadow.
  static List<BoxShadow> md(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkMd : _lightMd;

  /// Theme-aware large hover/elevated card shadow.
  static List<BoxShadow> lg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkLg : _lightLg;

  /// Theme-aware dramatic shadow for modals/sheets.
  static List<BoxShadow> xl(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkXl : _lightXl;

  /// Brand colored CTA glow (light mode only — dark mode skips the glow
  /// because it competes with neighboring surfaces).
  static List<BoxShadow> ctaBlueGlow(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) return const [];
    return BrandTokens.ctaBlueGlow;
  }

  static List<BoxShadow> ctaAmberGlow(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) return const [];
    return BrandTokens.ctaAmberGlow;
  }
}
