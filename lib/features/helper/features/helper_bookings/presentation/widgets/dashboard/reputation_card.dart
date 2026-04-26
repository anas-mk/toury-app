import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/custom_card.dart';

class ReputationCard extends StatelessWidget {
  final double rating;
  final VoidCallback onTap;

  const ReputationCard({super.key, required this.rating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        variant: CardVariant.elevated,
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: AppColor.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: AppColor.accentColor, size: 28),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Reputation',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'View your ratings and feedback',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
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
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColor.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rating',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Icon(
              Icons.arrow_forward_ios_rounded, 
              color: isDark ? Colors.white24 : Colors.black26, 
              size: 14
            ),
          ],
        ),
      ),
    );
  }
}
