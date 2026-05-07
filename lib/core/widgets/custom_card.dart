// lib/core/widgets/custom_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_color.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectivePadding = padding ?? const EdgeInsets.all(AppTheme.spaceLG);
    final effectiveRadius = borderRadius ?? AppTheme.radiusLG;

    Widget cardContent = Container(
      margin: margin,
      padding: effectivePadding,
      decoration: _buildDecoration(context, isDark, effectiveRadius),
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
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(effectiveRadius),
            child: cardContent,
          ),
        ),
      );
    }

    return cardContent;
  }

  BoxDecoration _buildDecoration(BuildContext context, bool isDark, double radius) {
    final theme = Theme.of(context);

    switch (variant) {
      case CardVariant.elevated:
        return BoxDecoration(
          color: backgroundColor ?? theme.cardTheme.color,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: AppTheme.shadowMedium(context),
          border: Border.all(
            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
            width: 0.5,
          ),
        );

      case CardVariant.outlined:
        return BoxDecoration(
          color: backgroundColor ?? theme.cardTheme.color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
            width: 1.5,
          ),
        );

      case CardVariant.filled:
        return BoxDecoration(
          color: backgroundColor ?? theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(radius),
        );

      case CardVariant.glass:
        return BoxDecoration(
          color: backgroundColor ?? 
              (isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: AppTheme.shadowLight(context),
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

    return CustomCard(
      onTap: onTap,
      isClickable: onTap != null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSM),
            decoration: BoxDecoration(
              color: (iconColor ?? theme.colorScheme.primary).withOpacity(0.1),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
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
    
    return CustomCard(
      onTap: onTap,
      isClickable: onTap != null,
      variant: CardVariant.filled,
      backgroundColor: color.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLG),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
