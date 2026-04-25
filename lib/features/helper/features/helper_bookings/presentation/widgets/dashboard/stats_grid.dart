import 'package:flutter/material.dart';
import '../../../domain/entities/helper_booking_entities.dart';

class StatsGrid extends StatelessWidget {
  final HelperDashboard dashboard;

  const StatsGrid({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem('Today\'s Income', '\$${dashboard.todayEarnings.toStringAsFixed(0)}', Icons.payments_rounded, const Color(0xFF00C896)),
      _StatItem('Pending', '${dashboard.pendingRequestsCount}', Icons.inbox_rounded, const Color(0xFFFFAB40)),
      _StatItem('Upcoming', '${dashboard.upcomingTripsCount}', Icons.calendar_today_rounded, const Color(0xFF6C63FF)),
      _StatItem('Success Rate', '${(dashboard.acceptanceRate * 100).toStringAsFixed(0)}%', Icons.verified_rounded, const Color(0xFF26C6DA)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: stat.color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: stat.color, size: 16),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              stat.value,
              style: TextStyle(
                color: stat.color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
