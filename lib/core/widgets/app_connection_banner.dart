// lib/core/widgets/app_connection_banner.dart
//
// Top-of-screen banner shown when the realtime connection is unhealthy.
// Replaces the inline implementation that previously lived in app.dart.

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

class AppConnectionBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AppConnectionBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Material(
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    color: theme.colorScheme.onErrorContainer,
                    size: AppSize.iconLg,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onErrorContainer,
                      backgroundColor:
                          theme.colorScheme.onErrorContainer.withValues(
                        alpha: 0.08,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      'Retry',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
