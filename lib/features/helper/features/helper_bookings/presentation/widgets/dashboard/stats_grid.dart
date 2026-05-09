import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/utils/currency_format.dart';
import '../../../domain/entities/helper_dashboard_entity.dart';

/// Backend may send [0, 1] ratio **or** [0, 100] percent — avoid 100 → 10000%.
String _acceptancePercentLabel(double rate) {
  if (rate.isNaN || rate < 0) return '—';
  if (rate <= 1.0) {
    return '${(rate * 100).round().clamp(0, 100)}%';
  }
  return '${rate.round().clamp(0, 100)}%';
}

/// Modern dashboard stats: a hero "Today" card showing earnings prominently,
/// followed by a 3-column compact stat row.
class StatsGrid extends StatelessWidget {
  final HelperDashboardEntity dashboard;

  /// Live pending count from [IncomingRequestsCubit] when loaded; falls back
  /// to [HelperDashboardEntity.pendingRequestsCount] when null.
  final int? pendingRequestsCountOverride;

  const StatsGrid({
    super.key,
    required this.dashboard,
    this.pendingRequestsCountOverride,
  });

  @override
  Widget build(BuildContext context) {
    final pending = pendingRequestsCountOverride ?? dashboard.pendingRequestsCount;
    return Column(
      children: [
        _EarningsHeroCard(amount: dashboard.todayEarnings),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.flash_on_rounded,
                label: 'Requests',
                value: '$pending',
                color: const Color(0xFFFF8C42),
                showBadge: pending > 0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.event_available_rounded,
                label: 'Upcoming',
                value: '${dashboard.upcomingTripsCount}',
                color: const Color(0xFF7B61FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.verified_rounded,
                label: 'Success',
                value: _acceptancePercentLabel(dashboard.acceptanceRate),
                color: const Color(0xFF00B8A9),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  EARNINGS HERO CARD (today)
// ──────────────────────────────────────────────────────────────────────────────

class _EarningsHeroCard extends StatelessWidget {
  final double amount;
  const _EarningsHeroCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.18 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative subtle gradient background
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF22C55E)
                        .withValues(alpha: palette.isDark ? 0.18 : 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Today\'s Earnings',
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.textMuted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E)
                                .withValues(alpha: palette.isDark ? 0.20 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                size: 10,
                                color: Color(0xFF22C55E),
                              ),
                              SizedBox(width: 2),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF22C55E),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          Money.code,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.textSecondary,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Money.egp(amount, showCode: false),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: palette.textPrimary,
                            letterSpacing: -0.8,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  COMPACT STAT TILE
// ──────────────────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool showBadge;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: palette.isDark ? 0.24 : 0.16),
                      color.withValues(alpha: palette.isDark ? 0.10 : 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              if (showBadge)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              fontSize: 22,
              letterSpacing: -0.5,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: palette.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
