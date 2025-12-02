// lib/core/widgets/custom_button.dart
import 'package:flutter/material.dart';
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

  // إضافة المعاملات الناقصة
  final Color? color;
  final double? height;
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
    this.height,
    this.borderRadius,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = _getButtonStyle(theme);
    final buttonHeight = height ?? customHeight ?? _getHeight();
    final width = customWidth ?? (isFullWidth ? double.infinity : null);

    final child = _buildContent(theme);

    return SizedBox(
      width: width,
      height: buttonHeight,
      child: _buildButton(buttonStyle, child),
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
      return SizedBox(
        width: _getLoadingSize(),
        height: _getLoadingSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _getLoadingColor(theme),
        ),
      );
    }

    final textWidget = Text(
      text,
      style: textStyle ?? _getTextStyle(theme),
    );

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: AppTheme.spaceSM),
          textWidget,
        ],
      );
    }

    return textWidget;
  }

  ButtonStyle _getButtonStyle(ThemeData theme) {
    final baseStyle = ButtonStyle(
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusMD),
        ),
      ),
      padding: WidgetStateProperty.all(_getPadding()),
      elevation: WidgetStateProperty.resolveWith<double>((states) {
        if (variant == ButtonVariant.text) return 0;
        if (states.contains(WidgetState.pressed)) return 0;
        return AppTheme.elevationSM;
      }),
    );

    // إذا تم تحديد لون مخصص
    if (color != null) {
      return baseStyle.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return color!.withOpacity(0.5);
          }
          return color!;
        }),
        foregroundColor: WidgetStateProperty.all(Colors.white),
      );
    }

    switch (variant) {
      case ButtonVariant.primary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return theme.colorScheme.primary.withOpacity(0.5);
            }
            return theme.colorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.all(
            theme.colorScheme.onPrimary,
          ),
        );

      case ButtonVariant.secondary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return theme.colorScheme.secondary.withOpacity(0.5);
            }
            return theme.colorScheme.secondary;
          }),
          foregroundColor: WidgetStateProperty.all(
            theme.colorScheme.onSecondary,
          ),
        );

      case ButtonVariant.outlined:
        return baseStyle.copyWith(
          side: WidgetStateProperty.all(
            BorderSide(
              color: color ?? theme.colorScheme.primary,
              width: 2,
            ),
          ),
          foregroundColor: WidgetStateProperty.all(
            color ?? theme.colorScheme.primary,
          ),
        );

      case ButtonVariant.text:
        return baseStyle.copyWith(
          foregroundColor: WidgetStateProperty.all(
            color ?? theme.colorScheme.primary,
          ),
        );

      case ButtonVariant.danger:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.redAccent.withOpacity(0.5);
            }
            return Colors.redAccent;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );

      case ButtonVariant.success:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.green.withOpacity(0.5);
            }
            return Colors.green;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    switch (size) {
      case ButtonSize.small:
        return AppTheme.labelMedium;
      case ButtonSize.large:
        return AppTheme.labelLarge.copyWith(fontSize: 18);
      default:
        return AppTheme.labelLarge;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMD,
          vertical: AppTheme.spaceSM,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLG,
          vertical: AppTheme.spaceLG,
        );
      default:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLG,
          vertical: AppTheme.spaceMD,
        );
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 40;
      case ButtonSize.large:
        return 56;
      default:
        return 50;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 18;
      case ButtonSize.large:
        return 26;
      default:
        return 22;
    }
  }

  double _getLoadingSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.large:
        return 28;
      default:
        return 24;
    }
  }

  Color _getLoadingColor(ThemeData theme) {
    if (variant == ButtonVariant.outlined || variant == ButtonVariant.text) {
      return color ?? theme.colorScheme.primary;
    }
    return Colors.white;
  }
}

// ============================================
// 🎯 Specialized Buttons
// ============================================

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
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        boxShadow: AppTheme.shadowLight(context),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: iconColor ?? Colors.white,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : Icon(icon, size: 24, color: color),
      label: Text(
        text,
        style: AppTheme.labelLarge.copyWith(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: BorderSide(color: color, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
      ),
    );
  }
}