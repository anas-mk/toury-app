import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// Frosted-glass card for use on top of MeshGradientBackground.
// 1 px translucent white border, BackdropFilter blur, low-alpha fill.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double sigma;
  final Color tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.sigma = 12,
    this.tint = const Color(0x29FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: const Color(0x66FFFFFF),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
