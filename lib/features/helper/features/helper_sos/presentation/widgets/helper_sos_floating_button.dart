import 'package:flutter/material.dart';

import '../../../../../../core/theme/brand_tokens.dart';

/// Round white SOS trigger — matches the user live-tracking control.
class HelperSosFloatingButton extends StatelessWidget {
  const HelperSosFloatingButton({
    super.key,
    required this.onPressed,
    this.size = 56,
  });

  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.emergency_rounded,
              color: BrandTokens.dangerRed,
              size: size * 0.46,
            ),
          ),
        ),
      ),
    );
  }
}
