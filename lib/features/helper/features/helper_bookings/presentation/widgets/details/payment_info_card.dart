import 'package:flutter/material.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../domain/entities/helper_booking_entities.dart';

class PaymentInfoCard extends StatelessWidget {
  final HelperBooking booking;
  const PaymentInfoCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [BrandTokens.primaryBlue, BrandTokens.primaryBlue.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: BrandTokens.primaryBlue.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR PAYOUT',
                  style: BrandTypography.caption(color: Colors.white.withValues(alpha: 0.7), weight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${booking.payout.toStringAsFixed(2)}',
                  style: BrandTokens.numeric(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (booking.status.toLowerCase() == 'completed')
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}
