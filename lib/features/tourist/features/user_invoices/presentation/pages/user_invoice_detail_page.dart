import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../domain/entities/invoice_entity.dart';
import '../cubit/user_invoices_cubit.dart';
import '../cubit/user_invoices_state.dart';
import '../widgets/invoice_status_badge.dart';

class UserInvoiceDetailPage extends StatelessWidget {
  final String invoiceId;
  final InvoiceEntity? initialInvoice;

  const UserInvoiceDetailPage({
    super.key,
    required this.invoiceId,
    this.initialInvoice,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = sl<UserInvoicesCubit>();
        if (initialInvoice != null) {
          cubit.setInitialInvoice(initialInvoice!);
        } else {
          cubit.getInvoiceDetail(invoiceId);
        }
        return cubit;
      },
      child: Scaffold(
        appBar: BasicAppBar(
          title: 'Invoice Details',
          showBackButton: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                // Share functionality could be implemented here
              },
            ),
          ],
        ),
        body: BlocBuilder<UserInvoicesCubit, UserInvoicesState>(
          builder: (context, state) {
            if (state is UserInvoiceDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is UserInvoicesError) {
              return Center(child: Text(state.message));
            }

            if (state is UserInvoiceDetailLoaded) {
              final invoice = state.invoice;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(invoice),
                    const SizedBox(height: 20),
                    _buildTripInfo(invoice),
                    const SizedBox(height: 20),
                    _buildPriceBreakdown(invoice),
                    const SizedBox(height: 20),
                    _buildPaymentInfo(invoice),
                    const SizedBox(height: 30),
                    CustomButton(
                      text: 'View Receipt (PDF)',
                      onPressed: () => context.push('/invoice-view/${invoice.invoiceId}'),
                      icon: Icons.picture_as_pdf_outlined,
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeader(InvoiceEntity invoice) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice.invoiceNumber,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                'Issued on ${DateFormat('MMM dd, yyyy').format(invoice.issuedAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          InvoiceStatusBadge(status: invoice.status),
        ],
      ),
    );
  }

  Widget _buildTripInfo(InvoiceEntity invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRIP INFORMATION',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow(Icons.person_outline, 'Helper', invoice.helperName),
              const Divider(height: 24),
              _buildInfoRow(Icons.location_on_outlined, 'Destination', invoice.destinationCity),
              const Divider(height: 24),
              _buildInfoRow(Icons.confirmation_number_outlined, 'Booking ID', '#${invoice.bookingId.substring(0, 8).toUpperCase()}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown(InvoiceEntity invoice) {
    // Mocking subtotal and commission for UI display since they aren't in the entity
    final subtotal = invoice.totalAmount * 0.9;
    final commission = invoice.totalAmount * 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRICE BREAKDOWN',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildPriceRow('Trip Fare', subtotal, invoice.currency),
              const SizedBox(height: 12),
              _buildPriceRow('Service Fee', commission, invoice.currency),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    '${invoice.totalAmount.toStringAsFixed(2)} ${invoice.currency}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(InvoiceEntity invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYMENT INFORMATION',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow(Icons.payment_outlined, 'Method', invoice.paymentMethod),
              const Divider(height: 24),
              _buildInfoRow(Icons.check_circle_outline, 'Payment Status', invoice.paymentStatus),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueAccent.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, String currency) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black87)),
        Text('${amount.toStringAsFixed(2)} $currency', style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
