import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/custom_card.dart';
import '../../../domain/entities/helper_profile_entity.dart';

class StatusGrid extends StatelessWidget {
  final HelperProfileEntity profile;
  final String accountStatus;

  const StatusGrid({
    super.key,
    required this.profile,
    required this.accountStatus,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppTheme.spaceMD,
      mainAxisSpacing: AppTheme.spaceMD,
      childAspectRatio: 2.5,
      children: [
        _buildStatusItem(
          context,
          icon: profile.isActive ? Icons.toggle_on : Icons.toggle_off,
          title: 'Active State',
          value: profile.isActive ? 'Active' : 'Inactive',
          color: profile.isActive ? Colors.green : Colors.grey,
        ),
        _buildStatusItem(
          context,
          icon: profile.isApproved ? Icons.check_circle : Icons.pending,
          title: 'Approval',
          value: profile.isApproved ? 'Approved' : 'Pending',
          color: profile.isApproved ? Colors.green : Colors.orangeAccent,
        ),
        _buildStatusItem(
          context,
          icon: Icons.directions_car,
          title: 'Car Registered',
          value: profile.car != null ? 'Yes' : 'No',
          color: profile.car != null ? Colors.blueAccent : Colors.grey,
        ),
        _buildStatusItem(
          context,
          icon: Icons.api,
          title: 'System Status',
          value: accountStatus.isNotEmpty ? accountStatus : 'Unknown',
          color: Colors.purpleAccent,
        ),
      ],
    );
  }

  Widget _buildStatusItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return CustomCard(
      variant: CardVariant.outlined,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM, vertical: AppTheme.spaceSM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
