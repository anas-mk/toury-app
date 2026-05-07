// lib/core/widgets/app_divider.dart
//
// Themed hairline divider that respects light/dark mode automatically.
// Use this everywhere a 1px line separates two pieces of content so the
// visual weight is consistent across the app.

import 'package:flutter/material.dart';

import '../theme/app_color.dart';

class AppDivider extends StatelessWidget {
  final double indent;
  final double endIndent;
  final double thickness;
  final double height;

  const AppDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.thickness = 1,
    this.height = 1,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Divider(
      color: palette.divider,
      thickness: thickness,
      height: height,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

/// Vertical divider counterpart.
class AppVerticalDivider extends StatelessWidget {
  final double width;
  final double thickness;
  final double indent;
  final double endIndent;

  const AppVerticalDivider({
    super.key,
    this.width = 1,
    this.thickness = 1,
    this.indent = 0,
    this.endIndent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return VerticalDivider(
      color: palette.divider,
      width: width,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
