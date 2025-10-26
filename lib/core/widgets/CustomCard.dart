import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final double borderRadius;
  final double elevation;
  final Color? shadowColor;
  final EdgeInsetsGeometry? margin;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor,
    this.borderRadius = 24,
    this.elevation = 12,
    this.shadowColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final bgColor = backgroundColor ??
        (isDarkMode
            ? Theme.of(context).cardColor.withOpacity(0.9)
            : Colors.white);

    final shadow = shadowColor ??
        (isDarkMode ? Colors.black54 : Colors.black.withOpacity(0.1));

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: elevation,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
