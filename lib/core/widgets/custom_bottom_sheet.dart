// lib/core/widgets/custom_bottom_sheet.dart
//
// Themed modal bottom sheet. The original API is preserved:
//   • static `CustomBottomSheet.show(...)` returning a Future
//   • title, subtitle, child, height, padding, isDismissible parameters
//
// Internals are modernized to match the rest of the design system —
// dark mode aware surface color, rounded top corners, subtle drag handle,
// and consistent paddings.

import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';
import '../theme/app_shadows.dart';

class CustomBottomSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? child;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool isDismissible;

  const CustomBottomSheet({
    super.key,
    this.title,
    this.subtitle,
    this.child,
    this.height,
    this.padding,
    this.isDismissible = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? subtitle,
    Widget? child,
    double? height,
    EdgeInsetsGeometry? padding,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      useSafeArea: true,
      builder: (_) => CustomBottomSheet(
        title: title,
        subtitle: subtitle,
        height: height,
        padding: padding,
        isDismissible: isDismissible,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final mediaHeight = MediaQuery.of(context).size.height;

    final initialSize = (height != null
            ? (height! / mediaHeight).clamp(0.25, 0.95)
            : 0.5)
        .toDouble();

    return DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: 0.25,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: palette.surfaceElevated,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
            boxShadow: AppShadows.xl(context),
          ),
          padding: padding ??
              const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              if (title != null) ...[
                Text(
                  title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
              if (child != null)
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    physics: const BouncingScrollPhysics(),
                    child: child!,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
