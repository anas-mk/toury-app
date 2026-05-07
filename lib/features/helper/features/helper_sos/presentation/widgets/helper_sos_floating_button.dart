import 'package:flutter/material.dart';
import '../../../../../../core/theme/brand_tokens.dart';

class HelperSosFloatingButton extends StatelessWidget {
  const HelperSosFloatingButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: BrandTokens.dangerRed.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: BrandTokens.dangerRed,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24, // AppTheme.spaceLG equivalent
              vertical: 14,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sos_rounded, color: BrandTokens.surfaceWhite, size: 24),
                SizedBox(width: 10),
                Text(
                  'SOS',
                  style: TextStyle(
                    color: BrandTokens.surfaceWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
