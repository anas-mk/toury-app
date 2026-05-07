import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../../../core/theme/brand_tokens.dart';

class SkeletonBookingCard extends StatelessWidget {
  const SkeletonBookingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: BrandTokens.borderSoft.withValues(alpha: 0.3),
      highlightColor: BrandTokens.borderSoft.withValues(alpha: 0.1),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 14, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(width: 80, height: 10, color: Colors.white),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 60,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(width: double.infinity, height: 12, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: 200, height: 12, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
