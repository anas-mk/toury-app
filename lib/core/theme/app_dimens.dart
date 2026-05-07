// lib/core/theme/app_dimens.dart
//
// Unified dimensional design tokens — spacing, radius, sizes, durations.
//
// This file is the single source of truth for layout numbers across the
// app. Pages must NOT hard-code numeric pixel values for paddings,
// border radii, or component heights — they should reference these
// tokens so the visual rhythm stays consistent in every screen.
//
// AppTheme already exports a subset of these (spaceXS / radiusMD / ...).
// Those legacy constants are kept for backward compatibility; new code
// should prefer the namespaced classes here for clarity.

import 'package:flutter/widgets.dart';

/// Eight-point spacing scale.
abstract class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double mega = 48.0;
  static const double giga = 64.0;

  static const double pageGutter = 20.0;
  static const double pageVertical = 16.0;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageGutter,
    vertical: pageVertical,
  );

  static const EdgeInsets pageHPadding = EdgeInsets.symmetric(
    horizontal: pageGutter,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
}

/// Border radius scale.
abstract class AppRadius {
  AppRadius._();

  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 18.0;
  static const double xl = 22.0;
  static const double xxl = 28.0;
  static const double pill = 999.0;
}

/// Component height + size tokens.
abstract class AppSize {
  AppSize._();

  static const double buttonSm = 40.0;
  static const double buttonMd = 48.0;
  static const double buttonLg = 56.0;
  static const double buttonXl = 60.0;

  static const double inputSm = 44.0;
  static const double inputMd = 52.0;
  static const double inputLg = 56.0;

  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 28.0;
  static const double icon2Xl = 32.0;
  static const double icon3Xl = 40.0;

  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 72.0;
  static const double avatarHero = 96.0;

  static const double appBar = 56.0;
  static const double appBarLarge = 96.0;
  static const double bottomNav = 64.0;

  static const double hairline = 1.0;
  static const double border = 1.5;
}

/// Standard animation durations.
abstract class AppDurations {
  AppDurations._();

  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration relaxed = Duration(milliseconds: 480);
  static const Duration storytelling = Duration(milliseconds: 700);
}
