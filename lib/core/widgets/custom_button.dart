// lib/core/widgets/custom_button.dart
//
// Primary button primitive used everywhere in the app.
//
// IMPORTANT: this widget's API is preserved — `CustomButton`,
// `SocialLoginButton`, and `IconOnlyButton` are referenced from 50+
// pages. Internals are modernized to use the unified design system
// tokens (AppColors, AppRadius, AppSize) so dark mode, button heights,
// border radii, and color states stay consistent.

import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';

enum ButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  danger,
  success,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isFullWidth;
  final double? customHeight;
  final double? customWidth;

  // Optional overrides
  final Color? color;
  final double? borderRadius;
  final TextStyle? textStyle;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isFullWidth = true,
    this.customHeight,
    this.customWidth,
    this.color,
    this.borderRadius,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    final buttonStyle = _getButtonStyle(theme, palette);
    final buttonHeight = customHeight ?? _heightFor(size);
    final width = customWidth ?? (isFullWidth ? double.infinity : null);

    return SizedBox(
      width: width,
      height: buttonHeight,
      child: _buildButton(buttonStyle, _buildContent(theme, palette)),
    );
  }

  Widget _buildButton(ButtonStyle style, Widget child) {
    switch (variant) {
      case ButtonVariant.outlined:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
      case ButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
      default:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
    }
  }

  Widget _buildContent(ThemeData theme, AppColors palette) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: _loadingSizeFor(size),
          height: _loadingSizeFor(size),
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: _loadingColor(palette),
          ),
        ),
      );
    }

    final textColor = _foregroundColor(palette);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: _iconSizeFor(size), color: textColor),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            text,
            style: textStyle ??
                _textStyleFor(theme, size).copyWith(color: textColor),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  ButtonStyle _getButtonStyle(ThemeData theme, AppColors palette) {
    final baseStyle = ButtonStyle(
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.md),
        ),
      ),
      padding: WidgetStateProperty.all(_paddingFor(size)),
      elevation: WidgetStateProperty.all(0),
      shadowColor: WidgetStateProperty.all(Colors.transparent),
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.pressed)) {
          final isFilled = variant == ButtonVariant.primary ||
              variant == ButtonVariant.secondary ||
              variant == ButtonVariant.danger ||
              variant == ButtonVariant.success;
          return isFilled
              ? Colors.white.withValues(alpha: 0.12)
              : palette.primary.withValues(alpha: 0.08);
        }
        return null;
      }),
    );

    switch (variant) {
      case ButtonVariant.primary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return palette.primary.withValues(alpha: 0.4);
            }
            return color ?? palette.primary;
          }),
          foregroundColor: WidgetStateProperty.all(palette.onPrimary),
        );

      case ButtonVariant.secondary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return palette.accent.withValues(alpha: 0.4);
            }
            return color ?? palette.accent;
          }),
          foregroundColor: WidgetStateProperty.all(palette.onAccent),
        );

      case ButtonVariant.outlined:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.resolveWith((states) {
            final c = color ?? palette.border;
            return BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? c.withValues(alpha: 0.4)
                  : c,
              width: 1.5,
            );
          }),
          foregroundColor: WidgetStateProperty.all(color ?? palette.primary),
        );

      case ButtonVariant.text:
        return baseStyle.copyWith(
          foregroundColor: WidgetStateProperty.all(color ?? palette.primary),
        );

      case ButtonVariant.danger:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return palette.danger.withValues(alpha: 0.4);
            }
            return palette.danger;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );

      case ButtonVariant.success:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return palette.success.withValues(alpha: 0.4);
            }
            return palette.success;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );
    }
  }

  TextStyle _textStyleFor(ThemeData theme, ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return theme.textTheme.labelMedium ?? AppTheme.labelMedium;
      case ButtonSize.large:
        return theme.textTheme.labelLarge?.copyWith(fontSize: 16) ??
            AppTheme.labelLarge.copyWith(fontSize: 16);
      case ButtonSize.medium:
        return theme.textTheme.labelLarge ?? AppTheme.labelLarge;
    }
  }

  Color _foregroundColor(AppColors palette) {
    if (color != null && variant == ButtonVariant.outlined) return color!;
    if (color != null && variant == ButtonVariant.text) return color!;

    switch (variant) {
      case ButtonVariant.primary:
        return palette.onPrimary;
      case ButtonVariant.secondary:
        return palette.onAccent;
      case ButtonVariant.outlined:
      case ButtonVariant.text:
        return palette.primary;
      case ButtonVariant.danger:
      case ButtonVariant.success:
        return Colors.white;
    }
  }

  EdgeInsetsGeometry _paddingFor(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        );
    }
  }

  double _heightFor(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return AppSize.buttonSm;
      case ButtonSize.large:
        return AppSize.buttonLg;
      case ButtonSize.medium:
        return AppSize.buttonMd;
    }
  }

  double _iconSizeFor(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return AppSize.iconSm;
      case ButtonSize.large:
        return AppSize.iconLg;
      case ButtonSize.medium:
        return AppSize.iconMd;
    }
  }

  double _loadingSizeFor(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.large:
        return 24;
      case ButtonSize.medium:
        return 20;
    }
  }

  Color _loadingColor(AppColors palette) {
    if (variant == ButtonVariant.outlined || variant == ButtonVariant.text) {
      return color ?? palette.primary;
    }
    return Colors.white;
  }
}

class SocialLoginButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, AppSize.buttonLg),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        backgroundColor: palette.surface,
        elevation: 0,
      ),
      child: isLoading
          ? Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: palette.primary,
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: AppSize.iconLg,
                  height: AppSize.iconLg,
                  child: icon,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  text,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
    );
  }
}

class IconOnlyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const IconOnlyButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = AppSize.buttonLg,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Material(
      color: backgroundColor ?? palette.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            icon,
            color: iconColor ?? palette.textPrimary,
            size: AppSize.iconLg,
          ),
        ),
      ),
    );
  }
}
