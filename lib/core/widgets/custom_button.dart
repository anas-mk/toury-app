// lib/core/widgets/custom_button.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_color.dart';

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
    final buttonStyle = _getButtonStyle(theme);
    final buttonHeight = customHeight ?? _getHeight();
    final width = customWidth ?? (isFullWidth ? double.infinity : null);

    return SizedBox(
      width: width,
      height: buttonHeight,
      child: _buildButton(buttonStyle, _buildContent(theme)),
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

  Widget _buildContent(ThemeData theme) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: _getLoadingSize(),
          height: _getLoadingSize(),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _getLoadingColor(theme),
          ),
        ),
      );
    }

    final Color? textColor = _getForegroundColor(theme);

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: _getIconSize(), color: textColor),
          const SizedBox(width: AppTheme.spaceSM),
        ],
        Text(
          text,
          style: textStyle ?? _getTextStyle(theme).copyWith(color: textColor),
          textAlign: TextAlign.center,
        ),
      ],
    );

    return content;
  }

  ButtonStyle _getButtonStyle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    final baseStyle = ButtonStyle(
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusMD),
        ),
      ),
      padding: WidgetStateProperty.all(_getPadding()),
      elevation: WidgetStateProperty.all(0),
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.pressed)) {
          return (variant == ButtonVariant.primary || variant == ButtonVariant.secondary)
              ? Colors.white.withOpacity(0.1)
              : theme.colorScheme.primary.withOpacity(0.1);
        }
        return null;
      }),
    );

    switch (variant) {
      case ButtonVariant.primary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return theme.colorScheme.primary.withOpacity(0.5);
            }
            return theme.colorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.all(theme.colorScheme.onPrimary),
        );

      case ButtonVariant.secondary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return theme.colorScheme.secondary.withOpacity(0.5);
            }
            return theme.colorScheme.secondary;
          }),
          foregroundColor: WidgetStateProperty.all(theme.colorScheme.onSecondary),
        );

      case ButtonVariant.outlined:
        return baseStyle.copyWith(
          side: WidgetStateProperty.all(
            BorderSide(
              color: color ?? theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
          foregroundColor: WidgetStateProperty.all(color ?? theme.colorScheme.primary),
        );

      case ButtonVariant.text:
        return baseStyle.copyWith(
          foregroundColor: WidgetStateProperty.all(color ?? theme.colorScheme.primary),
        );

      case ButtonVariant.danger:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColor.errorColor.withOpacity(0.5);
            }
            return AppColor.errorColor;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );

      case ButtonVariant.success:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColor.accentColor.withOpacity(0.5);
            }
            return AppColor.accentColor;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    final Color? textColor = _getForegroundColor(theme);
    
    switch (size) {
      case ButtonSize.small:
        return theme.textTheme.labelMedium!.copyWith(color: textColor);
      case ButtonSize.large:
        return theme.textTheme.labelLarge!.copyWith(fontSize: 16, color: textColor);
      default:
        return theme.textTheme.labelLarge!.copyWith(color: textColor);
    }
  }

  Color? _getForegroundColor(ThemeData theme) {
    if (color != null) return color;
    
    switch (variant) {
      case ButtonVariant.primary:
        return theme.colorScheme.onPrimary;
      case ButtonVariant.secondary:
        return theme.colorScheme.onSecondary;
      case ButtonVariant.outlined:
      case ButtonVariant.text:
        return theme.colorScheme.primary;
      case ButtonVariant.danger:
      case ButtonVariant.success:
        return Colors.white;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceSM);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG, vertical: AppTheme.spaceLG);
      default:
        return const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG, vertical: AppTheme.spaceMD);
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 40;
      case ButtonSize.large:
        return 60;
      default:
        return 56;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.large:
        return 24;
      default:
        return 20;
    }
  }

  double _getLoadingSize() {
    switch (size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.large:
        return 24;
      default:
        return 20;
    }
  }

  Color _getLoadingColor(ThemeData theme) {
    if (variant == ButtonVariant.outlined || variant == ButtonVariant.text) {
      return color ?? theme.colorScheme.primary;
    }
    return theme.colorScheme.onPrimary;
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
    final isDark = theme.brightness == Brightness.dark;

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
        side: BorderSide(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        backgroundColor: isDark ? AppColor.darkSurface : Colors.white,
        elevation: 0,
      ),
      child: isLoading
          ? Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
            )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 24, height: 24, child: icon),
                  const SizedBox(width: AppTheme.spaceMD),
                  Text(
                    text,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
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
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: backgroundColor ?? (isDark ? AppColor.darkSurface : AppColor.lightSurface),
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Icon(
            icon,
            color: iconColor ?? theme.colorScheme.onSurface,
            size: 24,
          ),
        ),
      ),
    );
  }
}
