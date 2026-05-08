import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_theme.dart';
import '../theme/brand_tokens.dart';
import 'brand/brand_kit.dart';

/// Brand gradient pair shared by every screen that shows a "hero" band.
///
/// Pass #4: the colors here are now informational only — the actual hero
/// canvas is a MeshGradientBackground from the brand kit. We keep this
/// constant exported because some legacy callers still pass it through.
const List<Color> kBrandGradient = [
  BrandTokens.primaryBlue,
  BrandTokens.primaryBlueDark,
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
    // Pass #4 — replace the legacy linear-gradient banner with the brand
    // MeshGradientBackground clipped by HeroBlobShape. The hero now has an
    // organic bottom edge instead of the old rounded-rect cut.
    return ClipPath(
      clipper: const _HeroBandBlobClipper(),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const RepaintBoundary(child: MeshGradientBackground()),
            // Subtle vignette so white text reads against the brightest
            // mesh blobs.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    BrandTokens.primaryBlueDark.withValues(alpha: 0.12),
                    BrandTokens.primaryBlueDark.withValues(alpha: 0.32),
                  ],
                ),
              ),
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
            child: OverflowBox(
              maxHeight: double.infinity,
              alignment: AlignmentDirectional.bottomStart,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
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
          ),
          ],
        ),
      ),
    );
  }
}

// Bottom-edge blob clipper used by HeroBand. Shape is a single cubic-
// bezier dip-and-rise so the hero never has a straight bottom line.
class _HeroBandBlobClipper extends CustomClipper<Path> {
  const _HeroBandBlobClipper();

  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 32);
    p.cubicTo(
      size.width * 0.25, size.height - 4,
      size.width * 0.55, size.height - 60,
      size.width * 0.78, size.height - 28,
    );
    p.cubicTo(
      size.width * 0.92, size.height - 14,
      size.width, size.height - 36,
      size.width, size.height - 56,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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
              color: theme.colorScheme.primary,
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
