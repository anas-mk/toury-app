import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../domain/entities/invoice_entity.dart';
import 'invoice_status_badge.dart';

class InvoiceCard extends StatelessWidget {
  final InvoiceEntity invoice;
  final VoidCallback onTap;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                invoice.invoiceNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              InvoiceStatusBadge(status: invoice.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                invoice.destinationCity,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd, yyyy').format(invoice.issuedAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL AMOUNT',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${invoice.totalAmount.toStringAsFixed(2)} ${invoice.currency}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ],
      ),
    );
  }
}
