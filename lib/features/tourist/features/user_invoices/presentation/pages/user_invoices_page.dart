import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/user_invoices_cubit.dart';
import '../cubit/user_invoices_state.dart';
import '../widgets/invoice_card.dart';

class UserInvoicesPage extends StatelessWidget {
  const UserInvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => sl<UserInvoicesCubit>()..getInvoices(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Wallet'),
              elevation: 0,
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<UserInvoicesCubit>().getInvoices(refresh: true);
              },
              child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payment Methods Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), shape: BoxShape.circle),
                              child: Icon(Icons.account_balance_wallet, size: 32, color: isDark ? Colors.white : Colors.black),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  SizedBox(height: 4),
                                  Text('Default payment method', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Recent Invoices', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              BlocBuilder<UserInvoicesCubit, UserInvoicesState>(
                builder: (context, state) {
                  if (state is UserInvoicesLoading) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                  }
                  if (state is UserInvoicesError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 60, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(state.message, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: () => context.read<UserInvoicesCubit>().getInvoices(refresh: true), child: const Text('Retry')),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state is UserInvoicesEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 80, color: isDark ? Colors.white24 : Colors.black12),
                            const SizedBox(height: 16),
                            const Text('No invoices yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('Invoices will appear here after your trip.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state is UserInvoicesLoaded) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final invoice = state.invoices[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: InvoiceCard(
                              invoice: invoice,
                              onTap: () => context.push('/invoice-detail/${invoice.invoiceId}', extra: invoice),
                            ),
                          );
                        },
                        childCount: state.invoices.length,
                      ),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
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
