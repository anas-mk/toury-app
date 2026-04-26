import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_theme.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
        builder: (context, state) {
          if (state is InvoiceSummaryLoading) return const _EarningsShimmer();

          final InvoiceSummaryEntity? summary =
              state is InvoiceSummaryLoaded ? state.summary : null;

          final fmt = NumberFormat('#,##0.00');

          return GestureDetector(
            onTap: () => context.push('/helper/invoices'),
            child: CustomCard(
              variant: CardVariant.elevated,
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceMD),
                    decoration: BoxDecoration(
                      color: AppColor.accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: AppColor.accentColor, size: 22),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Net Earnings',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        summary != null
                            ? Text(
                                '${summary.currency} ${fmt.format(summary.netAmount)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: AppColor.accentColor,
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
                          const SizedBox(height: 4),
                          Text(
                            '${summary.invoiceCount} invoices · ${summary.currency} ${fmt.format(summary.commissionAmount)} fees',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_forward_ios_rounded, 
                        color: isDark ? Colors.white24 : Colors.black26, 
                        size: 14
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Details',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark ? Colors.white24 : Colors.black26,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomCard(
      variant: CardVariant.elevated,
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Container(
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.white54 : Colors.black26,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
      ),
    );
  }
}
