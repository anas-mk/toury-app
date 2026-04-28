import 'package:flutter/material.dart';

import 'brand_tokens.dart';

/// Phase 1 (Tourist UI redesign): `AppColor` is now a thin compatibility
/// shim that forwards every public name to a `BrandTokens` value. The 43
/// existing call sites do not need to change — they automatically pick up
/// the RAFIQ palette (Nile Blue + Pyramid Yellow) instead of the previous
/// Uber-style black/white surface.
///
/// Helper- and Admin-side screens that read these constants will also pick
/// up the new palette. This is the single intentional cross-role visual
/// change documented in the plan.
class AppColor {
  // ── Primary ──────────────────────────────────────────────────────────
  static const Color primaryColor = BrandTokens.primaryBlue;
  static const Color darkPrimary = BrandTokens.primaryBlueDark;

  // ── Secondary / accent ───────────────────────────────────────────────
  // Used for "links / actions" — was Uber blue. We map it to the RAFIQ
  // primary so it stays cohesive with the new identity.
  static const Color secondaryColor = BrandTokens.primaryBlue;

  // ── Backgrounds ──────────────────────────────────────────────────────
  static const Color lightBackground = BrandTokens.bgSoft;
  static const Color darkBackground = Color(0xFF000000);
  static const Color lightSurface = BrandTokens.surfaceWhite;
  static const Color darkSurface = Color(0xFF1E1E1E);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color lightText = BrandTokens.textPrimary;
  static const Color darkText = Colors.white;
  static const Color lightTextSecondary = BrandTokens.textSecondary;
  static const Color darkTextSecondary = Color(0xFFAFAFAF);

  // ── Status / accents ─────────────────────────────────────────────────
  static const Color accentColor = BrandTokens.successGreen;
  static const Color errorColor = BrandTokens.dangerSos;
  static const Color warningColor = BrandTokens.warningAmber;

  // ── Cards ────────────────────────────────────────────────────────────
  static const Color lightCardColor = BrandTokens.surfaceWhite;
  static const Color darkCardColor = Color(0xFF1E1E1E);

  // ── Borders ──────────────────────────────────────────────────────────
  static const Color lightBorder = BrandTokens.borderSoft;
  static const Color darkBorder = Color(0xFF333333);

  // ── Misc legacy names ────────────────────────────────────────────────
  static const Color routeColor = BrandTokens.primaryBlue;
  static const Color destinationColor = BrandTokens.dangerSos;
}
