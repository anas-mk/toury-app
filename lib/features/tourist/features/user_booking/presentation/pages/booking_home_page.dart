import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';

class BookingHomePage extends StatelessWidget {
  const BookingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('book_a_helper')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spaceXL),
            _buildTypeCard(
              context,
              title: loc.translate('instant'),
              subtitle: 'Find an available helper right now',
              icon: Icons.bolt_rounded,
              color: AppColor.accentColor,
              onTap: () => context.push(AppRouter.instantSearch),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            _buildTypeCard(
              context,
              title: loc.translate('scheduled'),
              subtitle: 'Plan ahead and book for a future date',
              icon: Icons.calendar_today_rounded,
              color: AppColor.secondaryColor,
              onTap: () => context.push(AppRouter.scheduledSearch),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: AppTheme.spaceLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.headlineMedium.copyWith(color: color),
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    subtitle,
                    style: AppTheme.bodyMedium.copyWith(color: AppColor.lightTextSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
