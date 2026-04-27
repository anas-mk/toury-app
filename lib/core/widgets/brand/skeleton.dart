import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/brand_tokens.dart';

// Brand-tinted shimmer placeholder. Use everywhere data is loading
// instead of CircularProgressIndicator.
class SkeletonShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const SkeletonShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE7EAF6),
        highlightColor: const Color(0xFFF6F8FE),
        period: const Duration(milliseconds: 1400),
        child: child,
      ),
    );
  }
}

// Single rectangular skeleton block. Use to compose layouts that mirror
// the real content shape (so the transition into real content is calm).
class SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBlock({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: BrandTokens.bgSoft,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// Full skeleton card matching the helper-card visual in the helpers list.
class HelperCardSkeleton extends StatelessWidget {
  const HelperCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: BrandTokens.cardShadow,
      ),
      child: const SkeletonShimmer(
        child: Row(
          children: [
            SkeletonBlock(width: 64, height: 64, radius: 32),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(width: 140, height: 14),
                  SizedBox(height: 8),
                  SkeletonBlock(width: 90, height: 12),
                  SizedBox(height: 8),
                  SkeletonBlock(width: 200, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
