import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/custom_card.dart';
import '../../../domain/entities/helper_booking_entities.dart';

class StatsGrid extends StatelessWidget {
  final HelperDashboard dashboard;

  const StatsGrid({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final stats = [
      _StatItem('Daily Income', '\$${dashboard.todayEarnings.toStringAsFixed(0)}', Icons.payments_rounded, AppColor.accentColor),
      _StatItem('Requests', '${dashboard.pendingRequestsCount}', Icons.inbox_rounded, Colors.orange),
      _StatItem('Upcoming', '${dashboard.upcomingTripsCount}', Icons.calendar_today_rounded, theme.colorScheme.primary),
      _StatItem('Success Rate', '${(dashboard.acceptanceRate * 100).toStringAsFixed(0)}%', Icons.verified_rounded, Colors.blueAccent),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppTheme.spaceMD,
        mainAxisSpacing: AppTheme.spaceMD,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomCard(
      variant: CardVariant.elevated,
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceXS),
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(stat.icon, color: stat.color, size: 16),
          ),
          const Spacer(),
          Text(
            stat.value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: stat.color,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
