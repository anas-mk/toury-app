import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';

/// Bottom sheet UX aligned with helper chat quick replies; copy is traveler-focused.
class UserChatQuickRepliesSheet extends StatelessWidget {
  final void Function(String) onReply;

  const UserChatQuickRepliesSheet({super.key, required this.onReply});

  static const replies = [
    "I'm at the pickup spot",
    "Running a few minutes late",
    "Can you share your ETA?",
    "Thanks for accepting",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg + AppSpacing.xs,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quick replies',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.pageGutter),
          ...replies.map(
            (reply) => ListTile(
              title: Text(
                reply,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textPrimary,
                ),
              ),
              onTap: () {
                onReply(reply);
                Navigator.pop(context);
              },
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                color: palette.textMuted,
                size: AppSize.iconSm,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
