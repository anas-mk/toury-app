// lib/core/widgets/custom_card.dart
//
// Reusable card primitive used everywhere in the app. Original API
// (`CustomCard`, `InfoCard`, `StatCard`) is preserved — only the
// internals are modernized to use unified theme tokens.

import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';
import '../theme/app_shadows.dart';

enum CardVariant {
  elevated,
  outlined,
  filled,
  glass,
}

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final CardVariant variant;
  final VoidCallback? onTap;
  final bool isClickable;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.variant = CardVariant.elevated,
    this.onTap,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.lg);
    final effectiveRadius = borderRadius ?? AppRadius.lg;

    Widget cardContent = Container(
      margin: margin,
      padding: effectivePadding,
      decoration: _buildDecoration(context, palette, effectiveRadius),
      child: child,
    );

    if (variant == CardVariant.glass) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: cardContent,
        ),
      );
    }

    if (onTap != null || isClickable) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(effectiveRadius),
            child: Container(
              padding: effectivePadding,
              decoration: _buildDecoration(context, palette, effectiveRadius),
              child: child,
            ),
          ),
        ),
      );
    }

    return cardContent;
  }

  BoxDecoration _buildDecoration(
    BuildContext context,
    AppColors palette,
    double radius,
  ) {
    switch (variant) {
      case CardVariant.elevated:
        return BoxDecoration(
          color: backgroundColor ?? palette.surface,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: AppShadows.md(context),
          border: Border.all(color: palette.border, width: 0.5),
        );

      case CardVariant.outlined:
        return BoxDecoration(
          color: backgroundColor ?? palette.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: palette.border, width: 1.2),
        );

      case CardVariant.filled:
        return BoxDecoration(
          color: backgroundColor ??
              palette.primary.withValues(alpha: palette.isDark ? 0.10 : 0.05),
          borderRadius: BorderRadius.circular(radius),
        );

      case CardVariant.glass:
        return BoxDecoration(
          color: backgroundColor ??
              (palette.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.42)),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: palette.isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: AppShadows.sm(context),
        );
    }
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? iconColor;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final accent = iconColor ?? palette.primary;

    return CustomCard(
      onTap: onTap,
      isClickable: onTap != null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: accent, size: AppSize.iconLg),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: palette.textMuted,
            ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return CustomCard(
      onTap: onTap,
      isClickable: onTap != null,
      variant: CardVariant.filled,
      backgroundColor: color.withValues(alpha: palette.isDark ? 0.16 : 0.08),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: AppSize.iconLg, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
