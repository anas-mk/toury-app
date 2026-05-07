import 'package:flutter/material.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/custom_card.dart';

class ReputationCard extends StatelessWidget {
  final double rating;
  final VoidCallback onTap;

  const ReputationCard({super.key, required this.rating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        variant: CardVariant.elevated,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BrandTokens.successGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded, 
                color: BrandTokens.successGreen, 
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Reputation',
                    style: BrandTypography.body(weight: FontWeight.bold),
                  ),
                  Text(
                    'View your ratings and feedback',
                    style: BrandTypography.caption(
                      color: BrandTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: BrandTypography.headline(
                      color: BrandTokens.successGreen,
                    ),
                  ),
                Text(
                  'Rating',
                  style: BrandTypography.overline(
                    color: BrandTokens.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.arrow_forward_ios_rounded, 
              color: BrandTokens.textSecondary.withValues(alpha: 0.3), 
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
