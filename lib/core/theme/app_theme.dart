// lib/core/theme/app_theme.dart
//
// Single source of truth for the Material light + dark themes.
//
// All component themes (AppBar, Card, Inputs, Buttons, BottomNav, Sheets,
// Dialogs, Snackbars, Tabs, Chips, Dividers, ProgressIndicators) are
// configured here so screens can rely on `Theme.of(context)` and never
// need bespoke decorations for shared chrome.
//
// IMPORTANT: the legacy spacing/radius/elevation constants exposed on
// `AppTheme.spaceXS`, `AppTheme.radiusMD`, `AppTheme.elevationSM`, etc.
// are KEPT for backward compatibility — 60+ files reference them. New
// code should prefer `AppSpacing` / `AppRadius` from `app_dimens.dart`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../router/brand_page_route.dart';
import 'brand_tokens.dart';
import 'brand_tokens_dark.dart';

const PageTransitionsTheme _brandPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: BrandPageTransitionsBuilder(),
    TargetPlatform.iOS: BrandPageTransitionsBuilder(),
    TargetPlatform.fuchsia: BrandPageTransitionsBuilder(),
    TargetPlatform.linux: BrandPageTransitionsBuilder(),
    TargetPlatform.macOS: BrandPageTransitionsBuilder(),
    TargetPlatform.windows: BrandPageTransitionsBuilder(),
  },
);

class AppTheme {
  AppTheme._();

  // ============================================
  // 🎨 LEGACY SPACING SYSTEM (kept for compat)
  // ============================================
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double space2XL = 40.0;
  static const double space3XL = 48.0;

  // ============================================
  // 📐 LEGACY BORDER RADIUS SYSTEM
  // ============================================
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radius2XL = 32.0;
  static const double radiusFull = 9999.0;

  // ============================================
  // 🖼️ LEGACY ELEVATION SYSTEM
  // ============================================
  static const double elevationNone = 0.0;
  static const double elevationXS = 2.0;
  static const double elevationSM = 4.0;
  static const double elevationMD = 8.0;
  static const double elevationLG = 12.0;
  static const double elevationXL = 16.0;

  // ============================================
  // 📝 TYPOGRAPHY
  // ============================================
  static TextTheme _buildTextTheme(TextTheme base, Color textColor) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textColor,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textColor,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: textColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: textColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: textColor,
      ),
    );
  }

  // ── Legacy non-themed style getters (kept for compat) ────────────
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static TextStyle get headlineMedium =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600);
  static TextStyle get bodyLarge =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // ============================================
  // ☀️ LIGHT THEME
  // ============================================
  static ThemeData get lightTheme => _buildTheme(brightness: Brightness.light);

  // ============================================
  // 🌙 DARK THEME
  // ============================================
  static ThemeData get darkTheme => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();

    // ── Resolved tokens ───────────────────────────────────────────
    final scaffoldColor = isDark
        ? BrandTokensDark.bgScaffold
        : BrandTokens.bgSoft;
    final surfaceColor = isDark
        ? BrandTokensDark.surface
        : BrandTokens.surfaceWhite;
    final surfaceElevated = isDark
        ? BrandTokensDark.surfaceElevated
        : BrandTokens.surfaceWhite;
    final borderColor = isDark
        ? BrandTokensDark.borderSoft
        : BrandTokens.borderSoft;
    final textColor = isDark
        ? BrandTokensDark.textPrimary
        : BrandTokens.textPrimary;
    final textSecondary = isDark
        ? BrandTokensDark.textSecondary
        : BrandTokens.textSecondary;
    final primary = isDark
        ? BrandTokensDark.primaryBlue
        : BrandTokens.primaryBlue;
    final primaryStrong = isDark
        ? BrandTokensDark.primaryBlueDark
        : BrandTokens.primaryBlueDark;

    // ── Color scheme ──────────────────────────────────────────────
    final scheme =
        ColorScheme.fromSeed(
          seedColor: BrandTokens.primaryBlue,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: isDark
              ? BrandTokensDark.primaryBlueSoft
              : const Color(0xFFE0E3FF),
          onPrimaryContainer: isDark
              ? Colors.white
              : BrandTokens.primaryBlueDark,
          secondary: BrandTokens.accentAmber,
          onSecondary: Colors.white,
          secondaryContainer: isDark
              ? BrandTokensDark.accentAmberSoft
              : BrandTokens.accentAmberSoft,
          onSecondaryContainer: isDark
              ? BrandTokensDark.accentAmberText
              : BrandTokens.accentAmberText,
          tertiary: BrandTokens.accentAmber,
          onTertiary: BrandTokens.accentAmberText,
          error: BrandTokens.dangerSos,
          onError: Colors.white,
          errorContainer: isDark
              ? BrandTokensDark.dangerRedSoft
              : BrandTokens.dangerRedSoft,
          onErrorContainer: isDark ? Colors.white : BrandTokens.dangerSos,
          surface: surfaceColor,
          onSurface: textColor,
          onSurfaceVariant: textSecondary,
          surfaceContainerLowest: surfaceColor,
          surfaceContainerLow: surfaceColor,
          surfaceContainer: scaffoldColor,
          surfaceContainerHigh: surfaceElevated,
          surfaceContainerHighest: surfaceElevated,
          outline: borderColor,
          outlineVariant: isDark
              ? BrandTokensDark.borderTinted
              : BrandTokens.borderTinted,
          shadow: isDark ? BrandTokensDark.shadowDeep : BrandTokens.shadowSoft,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      pageTransitionsTheme: _brandPageTransitions,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldColor,
      canvasColor: surfaceColor,
      splashFactory: InkRipple.splashFactory,

      // ── AppBar ───────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: scaffoldColor,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        iconTheme: IconThemeData(color: textColor, size: 22),
        actionsIconTheme: IconThemeData(color: textColor, size: 22),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // ── Cards ─────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: BorderSide(color: borderColor),
        ),
        color: surfaceColor,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Inputs ────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: borderColor.withValues(alpha: 0.5)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: BrandTokens.dangerSos),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(
            color: BrandTokens.dangerSos,
            width: 1.5,
          ),
        ),
        hintStyle: GoogleFonts.inter(
          color: textSecondary.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(
          color: primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        errorStyle: GoogleFonts.inter(
          color: BrandTokens.dangerSos,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Buttons ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSM),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: borderColor, width: 1.5),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSM),
          ),
        ),
      ),

      // ── Bottom Navigation ─────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // ── Bottom Sheets ─────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        modalBackgroundColor: surfaceElevated,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: borderColor,
        dragHandleSize: const Size(40, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Dialogs ───────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: textSecondary,
        ),
      ),

      // ── Snackbar ──────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? BrandTokensDark.surfaceElevated
            : BrandTokens.textPrimary,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        elevation: 0,
        actionTextColor: BrandTokens.accentAmber,
      ),

      // ── Chip ──────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primary.withValues(alpha: isDark ? 0.18 : 0.10),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Tabs ──────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primary, width: 2.5),
          insets: const EdgeInsets.symmetric(horizontal: 4),
        ),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Switch / Checkbox / Radio ─────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : (isDark ? BrandTokensDark.textMuted : Colors.white),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : (isDark ? BrandTokensDark.borderSoft : BrandTokens.borderSoft),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: borderColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : borderColor,
        ),
      ),

      // ── Progress ──────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: borderColor,
        circularTrackColor: borderColor.withValues(alpha: 0.4),
      ),

      // ── Divider ───────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: spaceLG,
      ),
      dividerColor: borderColor,

      // ── List tile ─────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textColor,
        tileColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
      ),

      // ── Tooltip ───────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark
              ? BrandTokensDark.surfaceElevated
              : BrandTokens.textPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Popup menu ────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          side: BorderSide(color: borderColor),
        ),
        elevation: 0,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),

      // ── Floating Action Button ────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const StadiumBorder(),
      ),

      // ── Misc ──────────────────────────────────────────────────────
      iconTheme: IconThemeData(color: textColor, size: 22),
      primaryIconTheme: const IconThemeData(color: Colors.white, size: 22),
      textTheme: _buildTextTheme(base.textTheme, textColor),
      primaryTextTheme: _buildTextTheme(base.textTheme, Colors.white),

      // ── Selection / cursor ────────────────────────────────────────
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.25),
        selectionHandleColor: primary,
      ),

      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

      // Suppress the secondary tint MD3 likes to put on every elevated
      // surface — we use explicit colors instead so cards have predictable
      // contrast against the background.
      extensions: const [],
      colorSchemeSeed: null,
      shadowColor: isDark ? BrandTokensDark.shadowDeep : BrandTokens.shadowSoft,
      // Use the dynamic primary; ensures status icons colored via primary
      // refer to the theme-aware brand blue, not the constant token.
      primaryColor: primary,
      primaryColorDark: primaryStrong,
    );
  }

  // ============================================
  // 🎭 LEGACY THEME-AWARE BOX SHADOWS
  // (Kept for compat. Prefer AppShadows.* in app_shadows.dart.)
  // ============================================
  static List<BoxShadow> shadowLight(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.20),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> shadowMedium(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.30),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> shadowHeavy(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.40),
          blurRadius: 32,
          offset: const Offset(0, 14),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

// Backward compatibility export — `AppColor` is still used as a static
// import target throughout the codebase. The class lives in app_color.dart
// but is re-exported here to keep historic imports of `app_theme.dart`
// alone compiling.
// (No additional re-exports needed — Dart shows AppColor through its own
//  import path.)
