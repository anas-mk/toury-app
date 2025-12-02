// lib/core/widgets/custom_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CardVariant {
  elevated,    // بظل
  outlined,    // ببوردر
  filled,      // بخلفية ملونة
  glass,       // Glass morphism effect
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectivePadding = padding ??
        const EdgeInsets.all(AppTheme.spaceLG);

    final effectiveRadius = borderRadius ?? AppTheme.radiusXL;

    Widget cardContent = Container(
      margin: margin,
      padding: effectivePadding,
      decoration: _buildDecoration(context, isDark, effectiveRadius),
      child: child,
    );

    // Apply glass effect if needed
    if (variant == CardVariant.glass) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: cardContent,
        ),
      );
    }

    // Make clickable if needed
    if (onTap != null || isClickable) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  BoxDecoration _buildDecoration(
      BuildContext context,
      bool isDark,
      double radius,
      ) {
    final theme = Theme.of(context);

    switch (variant) {
      case CardVariant.elevated:
        return BoxDecoration(
          color: backgroundColor ??
              (isDark ? Colors.grey[900] : Colors.white),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: AppTheme.shadowMedium(context),
        );

      case CardVariant.outlined:
        return BoxDecoration(
          color: backgroundColor ??
              (isDark ? Colors.grey[900] : Colors.white),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade300,
            width: 1.5,
          ),
        );

      case CardVariant.filled:
        return BoxDecoration(
          color: backgroundColor ??
              theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(radius),
        );

      case CardVariant.glass:
        return BoxDecoration(
          color: backgroundColor ??
              (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: AppTheme.shadowLight(context),
        );
    }
  }
}

// ============================================
// 🎯 Specialized Cards
// ============================================

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

    return CustomCard(
      onTap: onTap,
      isClickable: onTap != null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSM),
            decoration: BoxDecoration(
              color: (iconColor ?? theme.colorScheme.primary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(
              icon,
              color: iconColor ?? theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  value,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.iconTheme.color?.withOpacity(0.4),
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
    return CustomCard(
      onTap: onTap,
      isClickable: onTap != null,
      variant: CardVariant.filled,
      backgroundColor: color.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            value,
            style: AppTheme.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            title,
            style: AppTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}