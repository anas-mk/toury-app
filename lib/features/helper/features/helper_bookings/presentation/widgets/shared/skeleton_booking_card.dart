import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_dimens.dart';

class SkeletonBookingCard extends StatelessWidget {
  const SkeletonBookingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final base = palette.border.withValues(alpha: palette.isDark ? 0.35 : 0.30);
    final highlight = palette.surface.withValues(alpha: palette.isDark ? 0.30 : 0.85);
    final block = palette.surface;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: AppSize.avatarMd + 4,
                  height: AppSize.avatarMd + 4,
                  decoration: BoxDecoration(
                    color: block,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 14, color: block),
                    const SizedBox(height: 6),
                    Container(width: 80, height: 10, color: block),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 60,
                  height: 28,
                  decoration: BoxDecoration(
                    color: block,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(width: double.infinity, height: 12, color: block),
            const SizedBox(height: AppSpacing.sm),
            Container(width: 200, height: 12, color: block),
          ],
        ),
      ),
    );
  }
}
