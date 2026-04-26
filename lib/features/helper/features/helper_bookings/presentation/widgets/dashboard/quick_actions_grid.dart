import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/widgets/custom_card.dart';
import '../../../../../../../core/router/app_router.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final actions = [
      _ActionItem('Requests', Icons.notifications_active_rounded, Colors.orange, 
          () => context.push(AppRouter.helperRequests)),
      _ActionItem('Upcoming', Icons.event_available_rounded, theme.colorScheme.primary, 
          () => context.push(AppRouter.helperUpcoming)),
      _ActionItem('History', Icons.history_rounded, Colors.blueAccent, 
          () => context.push(AppRouter.helperHistory)),
      _ActionItem('My Areas', Icons.map_rounded, AppColor.accentColor, 
          () => context.push(AppRouter.helperServiceAreas)),
      _ActionItem('Reports', Icons.flag_rounded, AppColor.errorColor, 
          () => context.push(AppRouter.helperReports)),
      _ActionItem('SOS', Icons.sos_rounded, AppColor.errorColor, 
          () => context.push(AppRouter.helperSos)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppTheme.spaceMD,
        mainAxisSpacing: AppTheme.spaceMD,
        childAspectRatio: 1.0,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: action.onTap,
      child: CustomCard(
        variant: CardVariant.elevated,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSM),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              action.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
