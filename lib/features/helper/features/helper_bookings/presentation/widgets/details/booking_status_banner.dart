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
      case 'pending':
        return (const Color(0xFFFFAB40), 'Pending Your Response', Icons.hourglass_empty_rounded);
      case 'confirmed':
      case 'accepted':
        return (BrandTokens.primaryBlue, 'Confirmed & Upcoming', Icons.check_circle_outline_rounded);
      case 'inprogress':
      case 'started':
        return (BrandTokens.successGreen, 'Currently In Progress', Icons.navigation_rounded);
      case 'completed':
        return (BrandTokens.textMuted, 'Trip Completed', Icons.done_all_rounded);
      case 'cancelled':
        return (BrandTokens.dangerRed, 'Cancelled', Icons.cancel_outlined);
      default:
        return (BrandTokens.textMuted, s.toUpperCase(), Icons.info_outline_rounded);
    }
  }
}
