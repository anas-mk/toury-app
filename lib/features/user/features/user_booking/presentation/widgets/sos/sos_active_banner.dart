import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';

class SosActiveBanner extends StatelessWidget {
  const SosActiveBanner({
    super.key,
    required this.onCancel,
    this.isPaused = false,
    this.isCancelling = false,
  });

  final VoidCallback onCancel;
  final bool isPaused;
  final bool isCancelling;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = isPaused ? 'SOS still active' : 'SOS Active';
    final body = isPaused
        ? 'Support is reviewing your case. Location streaming is paused.'
        : 'Support has been alerted. Your live location is being shared.';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMD,
          AppTheme.spaceSM,
          AppTheme.spaceMD,
          0,
        ),
        child: Material(
          elevation: 18,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColor.errorColor.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColor.errorColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emergency_share_rounded,
                    color: AppColor.errorColor,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColor.errorColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColor.lightTextSecondary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSM),
                TextButton(
                  onPressed: isCancelling ? null : onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColor.errorColor,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  child: isCancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cancel SOS'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}