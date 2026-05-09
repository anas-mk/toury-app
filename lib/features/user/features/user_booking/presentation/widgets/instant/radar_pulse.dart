import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';

/// Animated radar / pulse rings used by [WaitingForHelperPage].
///
/// Rings expand outward from the center while fading out, repeating in a
/// staggered loop. The center child is rendered above the rings.
class RadarPulse extends StatefulWidget {
  final Widget child;
  final Color color;
  final double size;

  const RadarPulse({
    super.key,
    required this.child,
    this.color = AppColor.accentColor,
    this.size = 220,
  });

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 3; i++) _ring(i),
              widget.child,
            ],
          );
        },
      ),
    );
  }

  Widget _ring(int index) {
    final progress = (_ctrl.value + index / 3.0) % 1.0;
    final scale = 0.5 + (progress * 0.6);
    final opacity = (1 - progress).clamp(0.0, 1.0);
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity * 0.5,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.color, width: 2),
          ),
        ),
      ),
    );
  }
}
