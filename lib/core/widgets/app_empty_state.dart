// lib/core/widgets/app_empty_state.dart
//
// Uniform empty-state component for lists, search results, and any
// "nothing here yet" surface. Pages should never hand-roll their own
// empty state — pass an icon, title, message, and optional CTA.

import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.action,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xxl,
      vertical: AppSpacing.huge,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 36,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ] else if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSize.buttonMd),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
