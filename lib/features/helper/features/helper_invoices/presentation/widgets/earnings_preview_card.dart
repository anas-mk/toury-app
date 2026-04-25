import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/di/injection_container.dart';
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

          final InvoiceSummaryEntity? summary =
              state is InvoiceSummaryLoaded ? state.summary : null;

          final fmt = NumberFormat('#,##0.00');

          return GestureDetector(
            onTap: () => context.push('/helper-invoices'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00C896).withValues(alpha: 0.12),
                    const Color(0xFF1A1F3C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C896).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFF00C896), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Net Earnings',
                            style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 2),
                        summary != null
                            ? Text(
                                '${summary.currency} ${fmt.format(summary.netAmount)}',
                                style: const TextStyle(
                                    color: Color(0xFF00C896),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              )
                            : const Text('— —',
                                style: TextStyle(color: Colors.white38, fontSize: 16)),
                        if (summary != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${summary.invoiceCount} invoices · Commission: ${summary.currency} ${fmt.format(summary.commissionAmount)}',
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    children: [
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                      SizedBox(height: 4),
                      Text('All Invoices',
                          style: TextStyle(color: Colors.white38, fontSize: 10)),
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
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}
