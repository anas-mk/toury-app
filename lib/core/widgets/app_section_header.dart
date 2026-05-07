// lib/core/widgets/app_section_header.dart
//
// Unified section header used everywhere a list of cards is grouped under
// a label. Replaces the three previously-competing implementations:
//   • BrandSectionTitle  (lib/core/widgets/brand_widgets.dart)
//   • SectionHeader      (lib/core/widgets/brand/section_header.dart)
//   • SectionTitle       (lib/core/widgets/hero_header.dart)
//
// The legacy widgets remain for backward compatibility but they now
// delegate to this new component so the visual is identical everywhere.

import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final EdgeInsetsGeometry padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.pageGutter,
      vertical: AppSpacing.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (actionIcon != null) ...[
                    const SizedBox(width: 2),
                    Icon(
                      actionIcon,
                      size: AppSize.iconSm,
                      color: palette.primary,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
