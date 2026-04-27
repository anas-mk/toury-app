import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_theme.dart';

/// Brand gradient pair shared by every screen that shows a "hero" band.
///
/// The two ends are the brand accent (Egyptian-tourism leaning teal-green)
/// and our secondary action blue. We avoid using black gradients on hero
/// surfaces because they look like an admin tool, not a tourism product.
const List<Color> kBrandGradient = [
  AppColor.accentColor,
  AppColor.secondaryColor,
];

/// Shared hero band rendered as a `SliverPersistentHeader` delegate.
///
/// Use this anywhere we previously hand-rolled a per-page hero. It enforces
/// the same paddings, the same radius, the same shadow, and the same back
/// button placement so the screens feel like one product.
class HeroSliverHeader extends SliverPersistentHeaderDelegate {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final Widget? footer;
  final List<Color> gradient;
  final bool showBack;
  final VoidCallback? onBack;
  final double height;

  HeroSliverHeader({
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.footer,
    this.gradient = kBrandGradient,
    this.showBack = true,
    this.onBack,
    this.height = 200,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return HeroBand(
      title: title,
      subtitle: subtitle,
      leadingIcon: leadingIcon,
      trailing: trailing,
      footer: footer,
      gradient: gradient,
      showBack: showBack,
      onBack: onBack,
      height: height,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    if (oldDelegate is! HeroSliverHeader) return true;
    return oldDelegate.title != title ||
        oldDelegate.subtitle != subtitle ||
        oldDelegate.leadingIcon != leadingIcon ||
        oldDelegate.height != height;
  }
}

/// Standalone hero band used in `Column`/`SafeArea` layouts (non-sliver).
///
/// Optional [footer] is rendered as a full-width row below title/subtitle
/// (useful for trip metadata pills, status chips, etc).
class HeroBand extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final Widget? footer;
  final List<Color> gradient;
  final bool showBack;
  final VoidCallback? onBack;
  final double height;

  const HeroBand({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.footer,
    this.gradient = kBrandGradient,
    this.showBack = true,
    this.onBack,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final mediaTop = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _HeroDotsPainter()),
          ),
          if (showBack)
            Positioned(
              top: mediaTop + 4,
              left: 4,
              child: Material(
                color: Colors.white.withValues(alpha: 0.18),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          Positioned(
            left: AppTheme.spaceLG,
            right: AppTheme.spaceLG,
            top: mediaTop + 56,
            bottom: footer != null ? 16 : 24,
            child: Column(
              mainAxisAlignment: footer != null
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (leadingIcon != null) ...[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          leadingIcon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMD),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppTheme.spaceMD),
                      trailing!,
                    ],
                  ],
                ),
                if (footer != null) ...[
                  const SizedBox(height: AppTheme.spaceMD),
                  footer!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    const step = 28.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Section title pattern: small uppercase eyebrow + bold title.
///
/// Use this everywhere a screen has stacked sections to keep the visual
/// rhythm identical from screen to screen.
class SectionTitle extends StatelessWidget {
  final String label;
  final String? subtitle;

  const SectionTitle(this.label, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColor.accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          // FlexFit.loose lets this widget be embedded inside a parent Row that
          // doesn't wrap us in Expanded. Under bounded constraints it still
          // wraps text to the available width; under unbounded constraints it
          // shrink-wraps at intrinsic size instead of asserting.
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColor.lightTextSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
