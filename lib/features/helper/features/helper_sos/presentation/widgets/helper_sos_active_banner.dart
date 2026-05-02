import 'package:flutter/material.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/app_theme.dart';

class HelperSosActiveBanner extends StatelessWidget {
  const HelperSosActiveBanner({
    super.key,
    required this.onCancel,
    this.isCancelling = false,
  });

  final VoidCallback onCancel;
  final bool isCancelling;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 18,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: BrandTokens.surfaceWhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: BrandTokens.dangerRed.withValues(alpha: 0.22),
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
                color: BrandTokens.dangerRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emergency_share_rounded,
                color: BrandTokens.dangerRed,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SOS ACTIVE',
                    style: BrandTokens.heading(fontSize: 14).copyWith(
                      fontWeight: FontWeight.w900,
                      color: BrandTokens.dangerRed,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Safety team has been alerted. Your live location is shared.',
                    style: BrandTokens.body(
                      color: BrandTokens.textSecondary,
                      fontSize: 12,
                    ).copyWith(height: 1.25),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            TextButton(
              onPressed: isCancelling ? null : onCancel,
              style: TextButton.styleFrom(
                foregroundColor: BrandTokens.dangerRed,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: isCancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: BrandTokens.dangerRed),
                    )
                  : const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
