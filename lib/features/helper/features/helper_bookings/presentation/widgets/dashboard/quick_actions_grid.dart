import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/helper/features/helper_reports/presentation/pages/helper_reports_page.dart';
import 'package:toury/features/helper/features/helper_sos/presentation/pages/helper_sos_page.dart';

import '../../../../../../../core/router/app_router.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem('Requests', Icons.notifications_active_rounded, const Color(0xFFFFAB40), 
          () => context.push(AppRouter.helperRequests)),
      _ActionItem('Upcoming', Icons.event_available_rounded, const Color(0xFF6C63FF), 
          () => context.push(AppRouter.helperUpcoming)),
      _ActionItem('History', Icons.history_rounded, const Color(0xFF26C6DA), 
          () => context.push(AppRouter.helperHistory)),
      _ActionItem('My Areas', Icons.map_rounded, const Color(0xFFFF8C69), 
          () => context.push(AppRouter.helperServiceAreas)),
      _ActionItem('Reports', Icons.flag_rounded, const Color(0xFFFF6B6B), 
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelperReportsPage()))),
      _ActionItem('SOS', Icons.sos_rounded, Colors.redAccent, 
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelperSosPage()))),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) => _ActionTile(action: actions[index]),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem(this.label, this.icon, this.color, this.onTap);
}

class _ActionTile extends StatelessWidget {
  final _ActionItem action;
  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: action.color.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              action.label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
