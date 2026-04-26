import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/widgets/custom_card.dart';
import '../../../../../../../core/widgets/custom_button.dart';
import '../../../domain/entities/helper_status_entity.dart';

class ProfileStatusCard extends StatelessWidget {
  final HelperStatusEntity status;
  final VoidCallback? onSubmitForReview;

  const ProfileStatusCard({
    super.key,
    required this.status,
    this.onSubmitForReview,
  });

  String _getStatusMessage(HelperStatusEntity status) {
    if (!status.onboardingComplete) {
      return "Complete your profile to continue";
    }
    if (status.approvalStatus == "Pending") {
      return "Your account is under review";
    }
    if (status.isApproved && status.isActive) {
      return "Your account is active";
    }
    if (!status.isApproved) {
      return "Waiting for admin approval";
    }
    return "Something went wrong";
  }

  IconData _getStatusIcon(HelperStatusEntity status) {
    if (status.isApproved && status.isActive) return Icons.check_circle_outline;
    if (!status.onboardingComplete) return Icons.warning_amber_rounded;
    return Icons.access_time_rounded;
  }

  Color _getStatusColor(HelperStatusEntity status) {
    if (status.isApproved && status.isActive) return Colors.green;
    if (!status.onboardingComplete) return Colors.orange;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor(status);

    return CustomCard(
      variant: CardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Status',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusMessage(status),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status.canSubmitForAdminReview) ...[
            const SizedBox(height: AppTheme.spaceMD),
            const Divider(),
            const SizedBox(height: AppTheme.spaceMD),
            CustomButton(
              text: 'Submit for Review',
              onPressed: onSubmitForReview ?? () {},
              variant: ButtonVariant.primary,
            ),
          ],
        ],
      ),
    );
  }
}
