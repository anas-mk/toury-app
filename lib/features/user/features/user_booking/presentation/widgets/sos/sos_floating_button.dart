import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';

class SosFloatingButton extends StatelessWidget {
  const SosFloatingButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColor.errorColor.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: AppColor.errorColor,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spaceLG,
              vertical: 14,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sos_rounded, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
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