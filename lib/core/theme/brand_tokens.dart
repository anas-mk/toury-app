import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// RAFIQ design tokens — Pass #4 creative palette.
///
/// Source-of-truth for every color, gradient, shadow, and font used by the
/// brand widget kit (`lib/core/widgets/brand/*`). Pages must NOT hard-code
/// hex codes; pull them from here so theming and dark-mode roll-outs are a
/// one-file change.
abstract class BrandTokens {
  BrandTokens._();

  // ── Core palette (from OtpEmailTemplateFactory.cs) ───────────────────────
  static const Color primaryBlue = Color(0xFF1B237E);
  static const Color primaryBlueDark = Color(0xFF0F1655);
  static const Color accentAmber = Color(0xFFF5A623);
  static const Color accentAmberSoft = Color(0xFFFEF3C7);
  static const Color accentAmberBorder = Color(0xFFFDE68A);
  static const Color accentAmberText = Color(0xFFB45309);

  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color bgSoft = Color(0xFFF4F5FB);
  static const Color borderSoft = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);

  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenSoft = Color(0xFFD1FAE5);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color dangerRedSoft = Color(0xFFFEE2E2);
  static const Color warningAmber = Color(0xFFF59E0B);

  // ── Glow / colored shadow tokens ─────────────────────────────────────────
  /// Soft amber glow used under amber CTAs (instead of black shadow).
  static const Color glowAmber = Color(0xFFFFE7A6);
  /// Soft blue glow used under blue CTAs.
  static const Color glowBlue = Color(0xFFC7CCFF);

  /// Soft elevation shadow tinted toward the brand (not gray).
  static const Color shadowSoft = Color(0x141B237E);
  static const Color shadowDeep = Color(0x261B237E);

  // ── Mesh-gradient palette (animated hero canvas) ─────────────────────────
  static const Color gradientMeshA = Color(0xFF1B237E);
  static const Color gradientMeshB = Color(0xFF6B5BFF);
  static const Color gradientMeshC = Color(0xFFF5A623);
  static const Color gradientMeshD = Color(0xFFFF6B9D);

  // ── Brand strings ────────────────────────────────────────────────────────
  static const String wordmark = 'RAFIQ';
  static const String tagline = 'Your Way, Your Tour.';

  // ── Linear gradients ─────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryBlueDark],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC04A), accentAmber],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), successGreen],
  );

  // ── Font helpers ─────────────────────────────────────────────────────────

  /// Pacifico — used ONLY for the RAFIQ wordmark.
  static TextStyle wordmarkStyle({double fontSize = 28, Color? color}) =>
      GoogleFonts.pacifico(
        fontSize: fontSize,
        color: color ?? surfaceWhite,
      );

  /// Outfit — modern geometric sans for headings + numbers.
  static TextStyle heading({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? textPrimary,
        height: height,
        letterSpacing: letterSpacing ?? -0.2,
      );

  /// Tabular figures — for prices, ETAs, counters.
  static TextStyle numeric({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) =>
      GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Inter body text helper.
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? textSecondary,
        height: height ?? 1.45,
      );

  static TextStyle taglineStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    return GoogleFonts.inter(
      fontSize: base?.fontSize ?? 14,
      fontWeight: FontWeight.w500,
      color: surfaceWhite.withValues(alpha: 0.92),
    );
  }

  // ── Reusable shadows ─────────────────────────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: shadowSoft,
      blurRadius: 32,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> ctaBlueGlow = [
    BoxShadow(
      color: glowBlue,
      blurRadius: 28,
      spreadRadius: -6,
      offset: Offset(0, 14),
    ),
  ];

  static const List<BoxShadow> ctaAmberGlow = [
    BoxShadow(
      color: glowAmber,
      blurRadius: 28,
      spreadRadius: -6,
      offset: Offset(0, 14),
    ),
  ];
}