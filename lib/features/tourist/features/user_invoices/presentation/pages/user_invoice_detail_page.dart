import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/brand_tokens.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final invoice = initialInvoice;

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Details')),
        body: const Center(child: Text('Invoice data not available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${invoice.invoiceNumber}', style: BrandTokens.heading(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1. Success Icon & Title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Payment Successful',
              style: BrandTokens.heading(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Issued on ${DateFormat('MMMM d, yyyy').format(invoice.issuedAt)}',
              style: BrandTokens.body(color: theme.disabledColor),
            ),
            const SizedBox(height: 32),

            // 2. Main Receipt Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('TRIP DETAILS'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Destination', invoice.destinationCity),
                  _buildInfoRow('Helper', invoice.helperName),
                  _buildInfoRow('Booking ID', '#${invoice.bookingId.substring(0, 8).toUpperCase()}'),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  
                  _buildSectionTitle('BILLING INFO'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Billed To', invoice.userName),
                  _buildInfoRow('Payment Method', invoice.paymentMethod),
                  _buildInfoRow('Status', invoice.paymentStatus.toUpperCase(), valueColor: Colors.green),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),

                  // Total Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount Paid',
                        style: BrandTokens.heading(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${invoice.currency} ${invoice.totalAmount.toStringAsFixed(2)}',
                        style: BrandTokens.numeric(
                          fontSize: 22,
                          color: BrandTokens.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            // 3. Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {},
              child: const Text('Need help with this trip?'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: BrandTokens.body(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: BrandTokens.primaryBlue.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: BrandTokens.body(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              style: BrandTokens.body(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
