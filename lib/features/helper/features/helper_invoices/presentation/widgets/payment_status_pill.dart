import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';

/// Single source of truth for payment-status presentation.
///
/// Replaces the previously duplicated `_StatusPill` (invoice_detail_page) and
/// `_StatusBadge` (invoices_page / wallet_hub_page) inline widgets.
class PaymentStatusPill extends StatelessWidget {
  final String status;
  final PaymentStatusPillSize size;

  const PaymentStatusPill({
    super.key,
    required this.status,
    this.size = PaymentStatusPillSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final s = status.toLowerCase();

    final Color color;
    final IconData icon;
    switch (s) {
      case 'paid':
        color = palette.success;
        icon = Icons.check_circle_rounded;
        break;
      case 'pending':
        color = palette.warning;
        icon = Icons.schedule_rounded;
        break;
      case 'cancelled':
      case 'canceled':
        color = palette.danger;
        icon = Icons.cancel_rounded;
        break;
      default:
        color = palette.textMuted;
        icon = Icons.info_outline_rounded;
    }

    final isCompact = size == PaymentStatusPillSize.compact;
    final hPad = isCompact ? AppSpacing.sm : AppSpacing.md;
    final vPad = isCompact ? AppSpacing.xxs : AppSpacing.sm;
    final iconSize = isCompact ? 11.0 : 13.0;
    final fontSize = isCompact ? 9.5 : null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm + AppSpacing.xs),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

enum PaymentStatusPillSize { compact, medium }
