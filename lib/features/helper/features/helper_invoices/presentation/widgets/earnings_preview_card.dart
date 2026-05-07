import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../cubit/helper_invoices_cubit.dart';
import '../../domain/entities/invoice_entities.dart';

/// A compact earnings preview card shown on the Helper Dashboard.
/// Self-contained: creates and disposes its own Cubit.
class EarningsPreviewCard extends StatefulWidget {
  const EarningsPreviewCard({super.key});

  @override
  State<EarningsPreviewCard> createState() => _EarningsPreviewCardState();
}

class _EarningsPreviewCardState extends State<EarningsPreviewCard> {
  late final HelperInvoicesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<HelperInvoicesCubit>()..loadSummary();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
        builder: (context, state) {
          if (state is InvoiceSummaryLoading) return const _EarningsShimmer();

          final InvoiceSummaryEntity? summary = state is InvoiceSummaryLoaded
              ? state.summary
              : null;

          final fmt = NumberFormat('#,##0.00');
          final theme = Theme.of(context);
          final palette = AppColors.of(context);

          return GestureDetector(
            onTap: () => context.pushNamed('helper-invoices'),
            child: CustomCard(
              variant: CardVariant.elevated,
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: palette.successSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: palette.success,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Net Earnings',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        summary != null
                            ? Text(
                                '${summary.currency} ${fmt.format(summary.netAmount)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: palette.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Text(
                                '— —',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                        if (summary != null) ...[
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            '${summary.invoiceCount} invoices · ${summary.currency} ${fmt.format(summary.commissionAmount)} fees',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.lg),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: palette.textMuted,
                        size: 14,
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Details',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EarningsShimmer extends StatelessWidget {
  const _EarningsShimmer();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return CustomCard(
      variant: CardVariant.elevated,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Container(
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(
          color: palette.surfaceInset.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
