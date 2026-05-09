// lib/core/widgets/app_snackbar.dart
//
// Theme-aware snackbar helpers. Use these instead of `ScaffoldMessenger`
// directly so success/error/info messages share the same shape, color,
// and icon language across the app.

import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';

enum AppSnackTone { neutral, success, info, warning, danger }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackTone tone = AppSnackTone.neutral,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    final (Color bg, Color fg, IconData icon) = switch (tone) {
      AppSnackTone.success => (palette.success, Colors.white, Icons.check_circle_rounded),
      AppSnackTone.info => (palette.primary, Colors.white, Icons.info_rounded),
      AppSnackTone.warning => (palette.warning, Colors.white, Icons.warning_amber_rounded),
      AppSnackTone.danger => (palette.danger, Colors.white, Icons.error_rounded),
      AppSnackTone.neutral => (palette.textPrimary, Colors.white, Icons.info_outline_rounded),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: bg,
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(icon, color: fg, size: AppSize.iconLg),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: fg,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, tone: AppSnackTone.success);

  static void info(BuildContext context, String message) =>
      show(context, message: message, tone: AppSnackTone.info);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, tone: AppSnackTone.warning);

  static void error(BuildContext context, String message) =>
      show(context, message: message, tone: AppSnackTone.danger);
}
