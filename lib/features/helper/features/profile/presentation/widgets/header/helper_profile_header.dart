import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../domain/entities/helper_profile_entity.dart';

class HelperProfileHeader extends StatelessWidget {
  final HelperProfileEntity profile;
  
  const HelperProfileHeader({
    super.key, 
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColor.primaryColor.withOpacity(0.1),
          backgroundImage: profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty
              ? NetworkImage(profile.profileImageUrl!)
              : null,
          child: profile.profileImageUrl == null || profile.profileImageUrl!.isEmpty
              ? const Icon(
                  Icons.person,
                  size: 40,
                  color: AppColor.primaryColor,
                )
              : null,
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName.isNotEmpty ? profile.fullName : 'Helper Profile',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Text(
                profile.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spaceSM),
              _buildStatusBadge(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    Color badgeColor;
    String statusText;

    if (profile.isApproved) {
      badgeColor = Colors.green;
      statusText = 'Approved';
    } else if (profile.onboardingStatus == 'REJECTED') {
      badgeColor = Colors.redAccent;
      statusText = 'Rejected';
    } else {
      badgeColor = Colors.orangeAccent;
      statusText = 'Pending Review';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            profile.isApproved ? Icons.verified : Icons.hourglass_top,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: theme.textTheme.labelMedium?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
