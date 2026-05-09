// Single source of truth for monetary formatting.
//
// Toury operates in Egyptian Pounds (EGP) — never use a hard-coded `$` prefix.
// Always go through [Money.egp] / [Money.egpCompact] so the formatting stays
// consistent across earnings, payouts, invoices, dialogs, and history items.

import 'package:intl/intl.dart';

abstract class Money {
  Money._();

  /// Currency code displayed alongside amounts (`EGP`).
  static const String code = 'EGP';

  /// Formatted EGP amount.
  ///
  /// Examples:
  ///   Money.egp(250)       -> "EGP 250.00"
  ///   Money.egp(1234.5)    -> "EGP 1,234.50"
  ///   Money.egp(50, decimals: false) -> "EGP 50"
  static String egp(num? amount, {bool decimals = true, bool showCode = true}) {
    final value = (amount ?? 0).toDouble();
    final pattern = decimals ? '#,##0.00' : '#,##0';
    final formatted = NumberFormat(pattern, 'en_US').format(value);
    return showCode ? '$code $formatted' : formatted;
  }

  /// Compact form for very large stat figures.
  ///
  /// Examples:
  ///   Money.egpCompact(12500)   -> "EGP 12.5K"
  ///   Money.egpCompact(1500000) -> "EGP 1.5M"
  ///   Money.egpCompact(940)     -> "EGP 940"
  static String egpCompact(num? amount, {bool showCode = true}) {
    final value = (amount ?? 0).toDouble();
    final formatted = NumberFormat.compact(locale: 'en_US').format(value);
    return showCode ? '$code $formatted' : formatted;
  }
}
