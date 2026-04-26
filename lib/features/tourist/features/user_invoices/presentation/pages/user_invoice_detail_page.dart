import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../domain/entities/invoice_entity.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInvoiceHeader(theme),
            const SizedBox(height: AppTheme.spaceXL),
            _buildBillingInfo(theme),
            const SizedBox(height: AppTheme.spaceXL),
            _buildLineItems(theme),
            const SizedBox(height: AppTheme.spaceXL),
            _buildTotalSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invoice #$invoiceId', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Paid on Oct 12, 2023', style: theme.textTheme.labelMedium),
      ],
    );
  }

  Widget _buildBillingInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Billed To', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Anas MK'),
        Text('Booking ID: B-9921', style: theme.textTheme.labelSmall),
      ],
    );
  }

  Widget _buildLineItems(ThemeData theme) {
    return Column(
      children: [
        _buildItemRow('Tour Helper Service (4 hrs)', '100.00 USD'),
        const Divider(),
        _buildItemRow('Platform Fee', '10.00 USD'),
        const Divider(),
        _buildItemRow('VAT (15%)', '16.50 USD'),
      ],
    );
  }

  Widget _buildItemRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTotalSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppColor.primaryColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text('126.50 USD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
