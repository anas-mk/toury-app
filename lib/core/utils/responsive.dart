import 'package:flutter/widgets.dart';

/// Lightweight responsive helper used across redesigned booking + chat
/// surfaces. We deliberately avoid pulling in a "responsive framework"
/// package — the rules we actually need are minimal (3 breakpoints,
/// a couple of clamps) and a 100-line file keeps build times fast.
///
/// Usage:
/// ```dart
/// final r = Responsive.of(context);
/// padding: EdgeInsets.all(r.gap),  // 14 / 18 / 22 by device
/// fontSize: r.fontTitle,           // 16 / 18 / 20
/// ```
class Responsive {
  final double width;
  final double height;
  final double textScale;
  final EdgeInsets viewPadding;
  final EdgeInsets viewInsets;

  const Responsive._({
    required this.width,
    required this.height,
    required this.textScale,
    required this.viewPadding,
    required this.viewInsets,
  });

  factory Responsive.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Responsive._(
      width: mq.size.width,
      height: mq.size.height,
      // Cap the system text scale so accessibility settings can never
      // blow our fixed-height bars / chips out of proportion.
      textScale: mq.textScaler.scale(1.0).clamp(0.85, 1.15),
      viewPadding: mq.viewPadding,
      viewInsets: mq.viewInsets,
    );
  }

  // ── breakpoints ──────────────────────────────────────────────────────
  /// Anything < 360 logical px wide (iPhone SE 1st gen, very old Android).
  bool get isCompact => width < 360;
  /// 360–599: typical phone (the great majority).
  bool get isPhone => width >= 360 && width < 600;
  /// 600–839: small tablet / large foldable open.
  bool get isTablet => width >= 600 && width < 840;
  /// >=840: large tablet, desktop.
  bool get isLarge => width >= 840;

  /// Clamp helper that picks one of three values per breakpoint.
  T pick<T>({required T compact, required T phone, T? tablet, T? large}) {
    if (isCompact) return compact;
    if (isLarge) return large ?? tablet ?? phone;
    if (isTablet) return tablet ?? phone;
    return phone;
  }

  // ── shorthand spacing tokens ─────────────────────────────────────────
  double get gapXS => pick(compact: 4.0, phone: 6.0, tablet: 8.0);
  double get gapSM => pick(compact: 8.0, phone: 10.0, tablet: 12.0);
  double get gap   => pick(compact: 12.0, phone: 16.0, tablet: 20.0);
  double get gapLG => pick(compact: 16.0, phone: 20.0, tablet: 26.0);
  double get gapXL => pick(compact: 22.0, phone: 28.0, tablet: 36.0);

  /// Horizontal page padding. Tablets get a max-width container instead
  /// of going edge-to-edge, so this returns the *padding* not the
  /// content width — pair with [contentMaxWidth] for the latter.
  double get pagePadding => pick(compact: 14.0, phone: 18.0, tablet: 22.0);

  /// Centred content max width. On tablets we pin to 720 so reading
  /// columns stay comfortable; on phones we just use the full width.
  double get contentMaxWidth => isTablet ? 720.0 : (isLarge ? 880.0 : width);

  // ── font sizes (already clamped by textScale) ────────────────────────
  double get fontDisplay => pick(compact: 22.0, phone: 24.0, tablet: 28.0);
  double get fontTitle   => pick(compact: 16.0, phone: 18.0, tablet: 20.0);
  double get fontBody    => pick(compact: 13.0, phone: 14.0, tablet: 15.0);
  double get fontSmall   => pick(compact: 11.0, phone: 12.0, tablet: 13.0);

  // ── component sizing ────────────────────────────────────────────────
  /// Height of the primary CTA in the bottom action bar.
  double get ctaHeight => pick(compact: 48.0, phone: 52.0, tablet: 56.0);

  /// Diameter of the hero avatar on detail pages.
  double get heroAvatar => pick(compact: 84.0, phone: 100.0, tablet: 116.0);

  /// Diameter of the small avatar shown in list rows / chat bar.
  double get rowAvatar => pick(compact: 48.0, phone: 56.0, tablet: 64.0);
}
