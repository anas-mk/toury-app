import 'package:flutter/material.dart';

import '../../theme/brand_tokens.dart';

enum BrandStatus {
  searching,
  confirmed,
  onTheWay,
  inProgress,
  completed,
  cancelled,
  info,
}

class StatusPill extends StatelessWidget {
  final BrandStatus status;
  final String label;
  final IconData? icon;
  final bool dense;

  const StatusPill({
    super.key,
    required this.status,
    required this.label,
    this.icon,
    this.dense = false,
  });

  ({Color fg, Color bg}) get _palette {
    switch (status) {
      case BrandStatus.searching:
        return (fg: BrandTokens.accentAmberText, bg: BrandTokens.accentAmberSoft);
      case BrandStatus.confirmed:
        return (fg: BrandTokens.primaryBlue, bg: Color(0xFFE0E3FF));
      case BrandStatus.onTheWay:
        return (fg: BrandTokens.gradientMeshB, bg: Color(0xFFE9E5FF));
      case BrandStatus.inProgress:
        return (fg: BrandTokens.successGreen, bg: BrandTokens.successGreenSoft);
      case BrandStatus.completed:
        return (fg: BrandTokens.textSecondary, bg: BrandTokens.bgSoft);
      case BrandStatus.cancelled:
        return (fg: BrandTokens.dangerRed, bg: BrandTokens.dangerRedSoft);
      case BrandStatus.info:
        return (fg: BrandTokens.primaryBlue, bg: BrandTokens.bgSoft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: p.fg, size: dense ? 13 : 15),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: BrandTokens.heading(
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: p.fg,
            ),
          ),
        ],
      ),
    );
  }
}
