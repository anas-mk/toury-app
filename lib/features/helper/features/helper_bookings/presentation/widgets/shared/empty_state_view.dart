import 'package:flutter/material.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: BrandTokens.borderSoft.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon, 
                color: BrandTokens.textSecondary.withValues(alpha: 0.3), 
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: BrandTypography.title(),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: BrandTypography.caption(
                color: BrandTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
