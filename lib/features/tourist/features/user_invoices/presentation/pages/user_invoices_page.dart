import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../cubit/user_invoices_cubit.dart';
import '../cubit/user_invoices_state.dart';
import '../widgets/invoice_card.dart';

class UserInvoicesPage extends StatelessWidget {
  const UserInvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<UserInvoicesCubit>()..getInvoices(),
      child: Scaffold(
        appBar: const BasicAppBar(
          title: 'My Invoices',
          showBackButton: true,
        ),
        body: BlocBuilder<UserInvoicesCubit, UserInvoicesState>(
          builder: (context, state) {
            if (state is UserInvoicesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is UserInvoicesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<UserInvoicesCubit>().getInvoices(refresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is UserInvoicesEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'No invoices yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Invoices will appear here after trip completion',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            if (state is UserInvoicesLoaded) {
              return RefreshIndicator(
                onRefresh: () async => context.read<UserInvoicesCubit>().getInvoices(refresh: true),
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: state.invoices.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final invoice = state.invoices[index];
                    return InvoiceCard(
                      invoice: invoice,
                      onTap: () => context.push('/invoice-detail/${invoice.invoiceId}', extra: invoice),
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
