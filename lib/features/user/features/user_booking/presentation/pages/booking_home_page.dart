import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/hero_header.dart';

/// Step 1 - booking entry point.
///
/// Visual hierarchy (Pass #2):
///   - Hero band reused from `core/widgets/hero_header.dart`.
///   - Big primary "Instant" card (gradient, dominant).
///   - Softer "Plan ahead" card (outlined, secondary).
///   - "Why RAFIQ" trust strip (3 chips).
class BookingHomePage extends StatelessWidget {
  const BookingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          HeroBand(
            title: 'Book a helper',
            subtitle: 'Pick instant for now, or plan ahead.',
            leadingIcon: Icons.travel_explore_rounded,
            onBack: () => Navigator.of(context).maybePop(),
            height: 200,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.huge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PrimaryInstantCard(
                  onTap: () => context.push(AppRouter.instantTripDetails),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SecondaryScheduledCard(
                  onTap: () => context.push(AppRouter.scheduledSearch),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const _WhyStrip(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Primary Instant card (dominant)
// ============================================================================

class _PrimaryInstantCard extends StatefulWidget {
  final VoidCallback onTap;
  const _PrimaryInstantCard({required this.onTap});

  @override
  State<_PrimaryInstantCard> createState() => _PrimaryInstantCardState();
}

class _PrimaryInstantCardState extends State<_PrimaryInstantCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColor.accentColor, AppColor.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AppColor.secondaryColor.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: const Text(
                      'INSTANT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Book a helper now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: AppSpacing.xs + AppSpacing.xxs),
              const Text(
                'Match instantly with a verified local helper near you. '
                'Most helpers respond in under 5 minutes.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm + AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Find helpers',
                          style: TextStyle(
                            color: AppColor.secondaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColor.secondaryColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Secondary Scheduled card (softer outlined card)
// ============================================================================

class _SecondaryScheduledCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SecondaryScheduledCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: AppColor.lightBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColor.secondaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: AppColor.secondaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Plan ahead',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pick a future date and confirm a helper.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColor.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColor.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Why RAFIQ strip
// ============================================================================

class _WhyStrip extends StatelessWidget {
  const _WhyStrip();

  @override
  Widget build(BuildContext context) {
    final items = const [
      _WhyChipData(
        icon: Icons.verified_user_rounded,
        title: 'Verified',
        subtitle: 'Helpers',
        color: AppColor.accentColor,
      ),
      _WhyChipData(
        icon: Icons.location_on_rounded,
        title: 'Live',
        subtitle: 'Tracking',
        color: AppColor.secondaryColor,
      ),
      _WhyChipData(
        icon: Icons.public_rounded,
        title: 'Local',
        subtitle: 'Expertise',
        color: AppColor.warningColor,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _WhyChip(data: items[i])),
          if (i != items.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _WhyChipData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _WhyChipData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _WhyChip extends StatelessWidget {
  final _WhyChipData data;
  const _WhyChip({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppColor.lightBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            data.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColor.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
