// Modernized "pickup → destination" timeline primitives.
//
// Provides three building blocks:
//   • [RouteStopRow]      – a single labelled stop with a haloed indicator dot.
//   • [RouteStopConnector] – the dotted vertical line between two stops.
//   • [RouteStopList]     – convenience wrapper that renders pickup + drop-off
//                            with a connector and matching halo dots.

import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_dimens.dart';

class RouteStopRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? label;
  final String value;
  final TextStyle? valueStyle;
  final bool emphasize;

  const RouteStopRow({
    super.key,
    required this.icon,
    required this.color,
    this.label,
    required this.value,
    this.valueStyle,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _HaloDot(icon: icon, color: color),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: valueStyle ??
                    theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                      color: palette.textPrimary,
                      height: 1.25,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Soft halo around a colored dot used as the timeline indicator.
class _HaloDot extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _HaloDot({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.40),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(icon, size: 10, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Dotted vertical separator between two [RouteStopRow]s.
class RouteStopConnector extends StatelessWidget {
  final double height;
  const RouteStopConnector({super.key, this.height = 28});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 13),
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _DashedLinePainter(
            color: palette.border,
            dashHeight: 3,
            dashGap: 4,
          ),
          child: const SizedBox(width: 2),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double dashGap;

  _DashedLinePainter({
    required this.color,
    required this.dashHeight,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashHeight), paint);
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) =>
      old.color != color ||
      old.dashHeight != dashHeight ||
      old.dashGap != dashGap;
}

/// Convenience pickup → destination block.
class RouteStopList extends StatelessWidget {
  final String pickup;
  final String destination;
  final bool showLabels;

  const RouteStopList({
    super.key,
    required this.pickup,
    required this.destination,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RouteStopRow(
          icon: Icons.circle,
          color: palette.success,
          label: showLabels ? 'PICKUP' : null,
          value: pickup,
          emphasize: true,
        ),
        const RouteStopConnector(),
        RouteStopRow(
          icon: Icons.location_on_rounded,
          color: palette.danger,
          label: showLabels ? 'DROP-OFF' : null,
          value: destination,
          emphasize: true,
        ),
      ],
    );
  }
}
