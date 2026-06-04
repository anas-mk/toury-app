import 'package:flutter/widgets.dart';

import '../localization/app_localizations.dart';

/// Locale-aware number formatting helpers.
///
/// When the active app locale is Arabic, ASCII digits (`0-9`) are
/// transliterated to Arabic-Indic / Eastern Arabic digits (`٠-٩`).
/// All other characters pass through untouched, so a string like
/// `"4.9 (124 reviews)"` becomes `"٤٫٩ (١٢٤ reviews)"` while preserving
/// the embedded English label.
///
/// Use the [BuildContext] extension below for ergonomic call sites:
///
/// ```dart
/// Text(context.localizeDigits('4.9'));
/// Text(context.localizeNumber(142));
/// ```
abstract class NumberFormatter {
  NumberFormatter._();

  static const Map<String, String> _arabicDigits = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
    '.': '٫',
  };

  /// Returns [input] with ASCII digits replaced by their Arabic-Indic
  /// equivalents when [isArabic] is `true`. Non-digit characters are
  /// preserved as-is.
  static String localize(String input, {required bool isArabic}) {
    if (!isArabic) return input;
    final buf = StringBuffer();
    for (final ch in input.characters) {
      buf.write(_arabicDigits[ch] ?? ch);
    }
    return buf.toString();
  }

  /// Convenience wrapper for numeric values. If [decimals] is `null`,
  /// the value is rendered with [num.toString] (no padding); otherwise
  /// it is fixed-point rounded to that many decimals first.
  static String localizeNumber(
    num value, {
    required bool isArabic,
    int? decimals,
  }) {
    final raw = decimals != null ? value.toStringAsFixed(decimals) : '$value';
    return localize(raw, isArabic: isArabic);
  }
}

/// Ergonomic [BuildContext] helpers so pages don't have to thread the
/// locale through every widget. They look up [AppLocalizations] once
/// and dispatch to [NumberFormatter].
extension NumberLocalizationX on BuildContext {
  /// `true` if the user's selected language is Arabic.
  bool get isArabicLocale {
    final l = AppLocalizations.of(this);
    return l.locale.languageCode == 'ar';
  }

  /// Replaces ASCII digits in [text] with Arabic-Indic digits when
  /// the app is in Arabic. No-op otherwise.
  String localizeDigits(String text) =>
      NumberFormatter.localize(text, isArabic: isArabicLocale);

  /// Locale-aware numeric formatting (`int` or `double`).
  String localizeNumber(num value, {int? decimals}) =>
      NumberFormatter.localizeNumber(
        value,
        isArabic: isArabicLocale,
        decimals: decimals,
      );
}
