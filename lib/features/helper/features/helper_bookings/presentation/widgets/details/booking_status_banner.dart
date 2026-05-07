import 'package:flutter/material.dart';

import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';


class BookingStatusBanner extends StatelessWidget {
  final String status;
  const BookingStatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _info(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: BrandTypography.body(
                color: color,
                weight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, String, IconData) _info(String s) {
    switch (s.toLowerCase()) {
      // Pending states
      case 'pending':
      case 'pendinghelperresponse':
        return (const Color(0xFFFFAB40), 'Pending Your Response', Icons.hourglass_empty_rounded);
      // Confirmed / accepted states (API returns 'AcceptedByHelper')
      case 'accepted':
      case 'acceptedbyhelper':
      case 'confirmed':
      case 'confirmedpaid':
        return (BrandTokens.primaryBlue, 'Confirmed & Upcoming', Icons.check_circle_outline_rounded);
      // Active trip states (API returns 'InProgress')
      case 'inprogress':
      case 'started':
      case 'active':
        return (BrandTokens.successGreen, 'Currently In Progress', Icons.navigation_rounded);
      // Completed
      case 'completed':
        return (BrandTokens.textMuted, 'Trip Completed', Icons.done_all_rounded);
      // Cancelled variants
      case 'cancelled':
      case 'cancelledbyhelper':
      case 'cancelledbytraveler':
      case 'cancelledbyadmin':
        return (BrandTokens.dangerRed, 'Cancelled', Icons.cancel_outlined);
      // Rejected
      case 'rejected':
      case 'declinedbyhelper':
        return (BrandTokens.dangerRed, 'Request Declined', Icons.block_rounded);
      default:
        return (BrandTokens.textMuted, s, Icons.info_outline_rounded);
    }
  }
}
