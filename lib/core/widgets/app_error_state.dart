// lib/core/widgets/app_error_state.dart
//
// Uniform error-state component with retry CTA. Use whenever a remote
// fetch fails and the page would otherwise be blank.

import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';

class AppErrorState extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData icon;
  final String retryLabel;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry padding;

  const AppErrorState({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.error_outline_rounded,
    this.retryLabel = 'Try again',
    this.onRetry,
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
              color: palette.dangerSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: palette.danger),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title ?? 'Something went wrong',
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
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: AppSize.iconMd),
              label: Text(retryLabel),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppSize.buttonMd),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact inline error tile — use inside cards, not full page rebuilds.
class AppErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorTile({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: AppSize.iconLg,
            color: palette.danger,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: 'Try again',
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, color: palette.danger),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}
