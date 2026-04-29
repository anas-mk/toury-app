import 'package:flutter/material.dart';

import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/custom_card.dart';
import '../../../domain/entities/helper_booking_entities.dart';


class TravelerInfoSection extends StatelessWidget {
  final HelperBooking booking;
  const TravelerInfoSection({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.travelerName,
                  style: BrandTypography.title(),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (booking.travelerCountry != null) ...[
                      Icon(Icons.public_rounded, size: 14, color: BrandTokens.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        booking.travelerCountry!,
                        style: BrandTypography.caption(color: BrandTokens.textMuted),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (booking.language != null) ...[
                      Icon(Icons.translate_rounded, size: 14, color: BrandTokens.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        booking.language!,
                        style: BrandTypography.caption(color: BrandTokens.textMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BrandTokens.bgSoft,
        border: Border.all(color: BrandTokens.borderSoft, width: 2),
      ),
      child: ClipOval(
        child: booking.travelerImage != null
            ? Image.network(
                booking.travelerImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 30, color: BrandTokens.textMuted),
              )
            : const Icon(Icons.person_rounded, size: 30, color: BrandTokens.textMuted),
      ),
    );
  }
}
