import 'package:flutter/material.dart';

import '../../theme/brand_tokens.dart';

// Solid white surface, 24-radius, brand-tinted soft shadow. The default
// container for any content card on a BgSoft canvas.
class BrandCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final List<BoxShadow>? customShadow;
  final Border? border;

  const BrandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.radius = 24,
    this.onTap,
    this.color,
    this.customShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: customShadow ?? BrandTokens.cardShadow,
        border: border,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
