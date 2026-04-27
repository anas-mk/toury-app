import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';

/// Lightweight shimmer-free skeleton box. Pulses opacity instead of using
/// the `shimmer` package so we don't add a new dependency.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppTheme.radiusSM,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final highlight = isDark
        ? AppColor.darkBorder.withValues(alpha: 0.4)
        : AppColor.lightBorder.withValues(alpha: 0.4);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(base, highlight, _controller.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Full helper-card skeleton used by [InstantHelpersListPage] while
/// `POST /search` is in flight.
class HelperCardSkeleton extends StatelessWidget {
  const HelperCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(
            width: 56,
            height: 56,
            borderRadius: 28,
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 14, width: 140),
                SizedBox(height: AppTheme.spaceSM),
                SkeletonBox(height: 12, width: 200),
                SizedBox(height: AppTheme.spaceMD),
                Row(
                  children: [
                    SkeletonBox(height: 22, width: 64, borderRadius: 11),
                    SizedBox(width: AppTheme.spaceSM),
                    SkeletonBox(height: 22, width: 64, borderRadius: 11),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
