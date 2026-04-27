import 'package:flutter/material.dart';

import '../../theme/brand_tokens.dart';

// Counts up from old value to new value over [duration]. Uses tabular
// figures so digits don't shift sideways.
class AnimatedCounter extends StatelessWidget {
  final num value;
  final String prefix;
  final String suffix;
  final int decimals;
  final Duration duration;
  final TextStyle? style;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 600),
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final txt = decimals == 0
            ? v.toStringAsFixed(0)
            : v.toStringAsFixed(decimals);
        return Text(
          '$prefix$txt$suffix',
          style: style ?? BrandTokens.numeric(fontSize: 32),
        );
      },
    );
  }
}
