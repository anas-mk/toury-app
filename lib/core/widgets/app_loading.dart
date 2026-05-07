// lib/core/widgets/app_loading.dart
//
// Themed loading indicators. Use these everywhere instead of bare
// `CircularProgressIndicator` so spinner sizes and colors stay consistent.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';

/// Compact circular spinner sized for inline contexts (buttons, list rows).
class AppSpinner extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const AppSpinner({
    super.key,
    this.size = 20,
    this.strokeWidth = 2.2,
    this.color,
  });

  /// 14 px spinner — fits inside chips and small buttons.
  const AppSpinner.tiny({super.key, this.color}) : size = 14, strokeWidth = 2.0;

  /// 28 px spinner — fits inside large buttons / dialogs.
  const AppSpinner.large({super.key, this.color})
    : size = 28,
      strokeWidth = 2.6;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? palette.primary),
      ),
    );
  }
}

/// Centered full-screen loading state with optional message + optional
/// inline (`fullScreen: false`) mode for inside lists.
class AppLoadingView extends StatelessWidget {
  final String? message;
  final bool fullScreen;
  final EdgeInsetsGeometry padding;

  const AppLoadingView({
    super.key,
    this.message,
    this.fullScreen = true,
    this.padding = const EdgeInsets.all(AppSpacing.xxl),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    final body = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppSpinner.large(),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );

    if (!fullScreen) return Center(child: body);
    return Center(child: body);
  }
}

/// Backward-friendly name used by screens expecting a single "AppLoading" widget.
class AppLoading extends AppLoadingView {
  const AppLoading({super.key, super.message, super.fullScreen, super.padding});
}

class AppSkeleton extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const AppSkeleton({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final palette = AppColors.of(context);
    return Shimmer.fromColors(
      baseColor: palette.surfaceInset,
      highlightColor: palette.surface,
      period: AppDurations.relaxed,
      child: child,
    );
  }
}

class AppSkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const AppSkeletonBlock({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.surfaceInset,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Full-bleed translucent overlay that covers an existing screen while a
/// blocking action runs. Use sparingly — most async actions should show
/// loading state inside the affected widget instead.
class AppLoadingOverlay extends StatelessWidget {
  final String? message;

  const AppLoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: palette.scrim,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: AppLoadingView(message: message, fullScreen: false),
          ),
        ),
      ),
    );
  }
}
