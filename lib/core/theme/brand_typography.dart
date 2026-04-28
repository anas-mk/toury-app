import 'package:flutter/material.dart';

import 'brand_tokens.dart';

/// Strict typography scale for the RAFIQ brand (Phase 1).
///
/// Single source of truth for the 6-step type scale. All font construction
/// goes through `BrandTokens.heading/body/numeric` so weights and font
/// families stay consistent.
///
///   Display  32 / 700
///   Headline 24 / 700
///   Title    18 / 600
///   Body     15 / 400 (Inter)
///   Caption  13 / 400 (Inter)
///   Overline 11 / 600
///
/// Weights are restricted to 400 / 500 / 600 / 700.
abstract class BrandTypography {
  BrandTypography._();

  static TextStyle display({Color? color}) => BrandTokens.heading(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: color ?? BrandTokens.textPrimary,
    height: 1.15,
  );

  static TextStyle headline({Color? color}) => BrandTokens.heading(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: color ?? BrandTokens.textPrimary,
    height: 1.2,
  );

  static TextStyle title({Color? color, FontWeight? weight}) =>
      BrandTokens.heading(
        fontSize: 18,
        fontWeight: weight ?? FontWeight.w600,
        color: color ?? BrandTokens.textPrimary,
        height: 1.3,
      );

  static TextStyle body({Color? color, FontWeight? weight}) => BrandTokens.body(
    fontSize: 15,
    fontWeight: weight ?? FontWeight.w400,
    color: color ?? BrandTokens.textPrimary,
    height: 1.5,
  );

  static TextStyle caption({Color? color, FontWeight? weight}) =>
      BrandTokens.body(
        fontSize: 13,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? BrandTokens.textSecondary,
        height: 1.45,
      );

  static TextStyle overline({Color? color}) => BrandTokens.heading(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: color ?? BrandTokens.textMuted,
    letterSpacing: 0.6,
    height: 1.4,
  );
}