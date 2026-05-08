import 'package:flutter/material.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/custom_card.dart';
import '../../../domain/entities/helper_dashboard_entity.dart';

class StatsGrid extends StatelessWidget {
  final HelperDashboardEntity dashboard;

  const StatsGrid({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem(
        'Daily Income',
        '\$${dashboard.todayEarnings.toStringAsFixed(0)}',
        Icons.payments_rounded,
        BrandTokens.successGreen,
      ),
      _StatItem(
        'Requests',
        '${dashboard.pendingRequestsCount}',
        Icons.inbox_rounded,
        BrandTokens.warningAmber,
      ),
      _StatItem(
        'Upcoming',
        '${dashboard.upcomingTripsCount}',
        Icons.calendar_today_rounded,
        BrandTokens.accentAmber,
      ),
      _StatItem(
        'Success Rate',
        '${(dashboard.acceptanceRate * 100).toStringAsFixed(0)}%',
        Icons.verified_rounded,
        BrandTokens.primaryBlue,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) => _StatCard(stat: stats[index]),
    );
  }
}

class _StatItem {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatItem stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      variant: CardVariant.elevated,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(stat.icon, color: stat.color, size: 16),
          ),
          const Spacer(),
          Text(
            stat.value,
            style: BrandTypography.title(
              color: stat.color,
            ),
          ),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BrandTypography.overline(
              color: BrandTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
