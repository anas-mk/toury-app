import 'package:flutter/material.dart';

// Animated radar pulse: 3 concentric circles expanding and fading.
// Used as a "live" / "searching" / "on the way" indicator.
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  final int rings;
  final Duration period;

  const PulseDot({
    super.key,
    this.color = const Color(0xFF10B981),
    this.size = 14,
    this.rings = 3,
    this.period = const Duration(milliseconds: 1600),
  });

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: widget.period)..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxScale = 3.6;
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size * maxScale,
        height: widget.size * maxScale,
        child: AnimatedBuilder(
          animation: _ctl,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < widget.rings; i++)
                  _Ring(
                    progress: ((_ctl.value + i / widget.rings) % 1.0),
                    color: widget.color,
                    base: widget.size,
                    maxScale: maxScale,
                  ),
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double progress;
  final Color color;
  final double base;
  final double maxScale;
  const _Ring({
    required this.progress,
    required this.color,
    required this.base,
    required this.maxScale,
  });

  @override
  Widget build(BuildContext context) {
    final scale = 1 + (maxScale - 1) * progress;
    final alpha = (1 - progress).clamp(0.0, 1.0) * 0.45;
    return IgnorePointer(
      child: Container(
        width: base * scale,
        height: base * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: alpha),
            width: 2,
          ),
        ),
      ),
    );
  }
}
