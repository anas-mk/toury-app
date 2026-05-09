import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/utils/currency_format.dart';
import '../../domain/entities/invoice_entities.dart';
import 'payment_status_pill.dart';

/// Shared invoice card used in both `InvoicesPage` and `WalletHubPage`.
///
/// Tapping the card navigates to the invoice detail page using the
/// `helper-invoice-detail` go_router name.
class InvoiceListItem extends StatelessWidget {
  final InvoiceEntity invoice;
  final EdgeInsets? margin;

  const InvoiceListItem({super.key, required this.invoice, this.margin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final dateFmt = DateFormat('MMM d, yyyy');
    final isPaid = invoice.paymentStatus.toLowerCase() == 'paid';
    final accent = isPaid ? palette.success : palette.warning;

    return Container(
      margin: margin ??
          const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl + AppSpacing.xs),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: palette.isDark ? 0.18 : 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl + AppSpacing.xs),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl + AppSpacing.xs),
          onTap: () => context.pushNamed(
            'helper-invoice-detail',
            pathParameters: {'id': invoice.invoiceId},
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StatusStripe(color: accent),
                const SizedBox(width: AppSpacing.md + AppSpacing.xs),
                _Avatar(color: accent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${invoice.invoiceNumber}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        invoice.userName.isEmpty ? '—' : invoice.userName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: palette.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (invoice.destinationCity.isNotEmpty)
                            _MetaChip(
                              icon: Icons.location_on_rounded,
                              text: invoice.destinationCity,
                            ),
                          if (invoice.issuedAt != null)
                            _MetaChip(
                              icon: Icons.event_rounded,
                              text: dateFmt.format(invoice.issuedAt!),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Money.egp(invoice.totalAmount),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    PaymentStatusPill(
                      status: invoice.paymentStatus,
                      size: PaymentStatusPillSize.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusStripe extends StatelessWidget {
  final Color color;
  const _StatusStripe({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.55)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final Color color;
  const _Avatar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Icon(Icons.receipt_long_rounded, color: color, size: 22),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: palette.textMuted, size: 11),
        const SizedBox(width: 2),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.textMuted,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}
