import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/brand_tokens.dart';

/// Legacy helper home placeholder (shell route uses [HelperDashboardPage]).
/// Kept styled with brand tokens for consistency if reused.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppTheme.spaceLG),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceLG),
                    decoration: BoxDecoration(
                      gradient: BrandTokens.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      boxShadow: BrandTokens.ctaBlueGlow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partner hub',
                          style: BrandTokens.heading(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceSM),
                        Text(
                          'Trips, earnings, and availability — open Home for your dashboard.',
                          style: BrandTokens.body(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXL),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
