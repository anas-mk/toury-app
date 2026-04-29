import 'package:flutter/material.dart';
import '../../../../../../core/theme/brand_tokens.dart';

class HelperSosActiveBanner extends StatelessWidget {
  const HelperSosActiveBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: BrandTokens.dangerRed,
        boxShadow: [
          BoxShadow(
            color: BrandTokens.dangerRed.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: BrandTokens.surfaceWhite, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOS ACTIVE',
                  style: BrandTokens.heading(fontSize: 16).copyWith(
                    color: BrandTokens.surfaceWhite,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Safety team has been alerted',
                  style: BrandTokens.body(
                    color: BrandTokens.surfaceWhite.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
