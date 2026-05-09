// lib/core/widgets/app_dialog.dart
//
// Themed dialog primitives. Use these helpers so confirmation flows look
// consistent everywhere instead of mixing `AlertDialog`, `CupertinoAlert`,
// and bespoke modals.

import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';

enum AppDialogTone { neutral, danger, success, warning }

/// Confirmation dialog with optional tone-specific iconography.
///
/// Returns `true` if the user taps the confirm button, `false` otherwise.
class AppDialog {
  AppDialog._();

  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    AppDialogTone tone = AppDialogTone.neutral,
    IconData? icon,
    bool barrierDismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => _AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        tone: tone,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  static Future<void> info({
    required BuildContext context,
    required String title,
    String? message,
    String okLabel = 'OK',
    IconData? icon,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: okLabel,
        cancelLabel: null,
        tone: AppDialogTone.neutral,
        icon: icon,
      ),
    );
  }
}

class _AppConfirmDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String confirmLabel;
  final String? cancelLabel;
  final AppDialogTone tone;
  final IconData? icon;

  const _AppConfirmDialog({
    required this.title,
    required this.confirmLabel,
    required this.tone,
    this.message,
    this.cancelLabel,
    this.icon,
  });

  Color _toneColor(AppColors palette) {
    switch (tone) {
      case AppDialogTone.danger:
        return palette.danger;
      case AppDialogTone.success:
        return palette.success;
      case AppDialogTone.warning:
        return palette.warning;
      case AppDialogTone.neutral:
        return palette.primary;
    }
  }

  Color _toneSoft(AppColors palette) {
    switch (tone) {
      case AppDialogTone.danger:
        return palette.dangerSoft;
      case AppDialogTone.success:
        return palette.successSoft;
      case AppDialogTone.warning:
        return palette.warningSoft;
      case AppDialogTone.neutral:
        return palette.primarySoft;
    }
  }

  IconData? _toneIcon() {
    if (icon != null) return icon;
    switch (tone) {
      case AppDialogTone.danger:
        return Icons.warning_amber_rounded;
      case AppDialogTone.success:
        return Icons.check_circle_outline_rounded;
      case AppDialogTone.warning:
        return Icons.error_outline_rounded;
      case AppDialogTone.neutral:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final accent = _toneColor(palette);
    final accentSoft = _toneSoft(palette);
    final dialogIcon = _toneIcon();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxl,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (dialogIcon != null) ...[
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(dialogIcon, size: 32, color: accent),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
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
            const SizedBox(height: AppSpacing.xxl),
            if (cancelLabel != null) ...[
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  minimumSize: const Size(0, AppSize.buttonMd),
                ),
                child: Text(confirmLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: palette.textSecondary,
                  minimumSize: const Size(0, AppSize.buttonMd),
                ),
                child: Text(cancelLabel!),
              ),
            ] else
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  minimumSize: const Size(0, AppSize.buttonMd),
                ),
                child: Text(confirmLabel),
              ),
          ],
        ),
      ),
    );
  }
}
