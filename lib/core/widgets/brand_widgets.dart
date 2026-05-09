// lib/core/widgets/brand_widgets.dart
//
// Legacy brand widget shims kept for backward compatibility with screens
// imported BEFORE the new `brand/` widget kit existed.
//
// IMPORTANT: every type here previously hard-coded its own color/shadow
// values, sometimes conflicting with the canonical brand kit (most
// notably `BrandCard`, which had two competing implementations). They
// are now thin theme-aware wrappers around the unified design system,
// so every existing import keeps compiling but renders the modern look.
//
// New screens should import the canonical brand kit instead:
//   import 'package:toury/core/widgets/brand/brand_kit.dart';

import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';
import '../theme/app_shadows.dart';
import 'app_section_header.dart';

/// Legacy section title — delegates to the unified [AppSectionHeader].
class BrandSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const BrandSectionTitle(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(
      title: title,
      subtitle: subtitle,
      padding: EdgeInsets.zero,
    );
  }
}

/// Legacy brand card. Renamed under-the-hood: this is the SAME class
/// callers historically imported from `brand_widgets.dart`, but it now
/// renders identically to the canonical card in `brand/brand_card_v2.dart`.
class BrandCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final VoidCallback? onTap;

  const BrandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin = EdgeInsets.zero,
    this.radius = AppRadius.lg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    final card = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.border),
        boxShadow: AppShadows.sm(context),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Legacy primary action button. Delegates to [FilledButton] with
/// app-themed styling.
class BrandPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool visualEnabled;

  const BrandPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.isLoading,
    required this.onPressed,
    this.visualEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final interactive = onPressed != null && !isLoading;
    final muted = interactive && !visualEnabled;

    return Opacity(
      opacity: isLoading ? 1.0 : (muted ? 0.55 : 1.0),
      child: SizedBox(
        height: AppSize.buttonLg,
        child: FilledButton(
          onPressed: interactive ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: palette.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: AppSize.iconLg),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Legacy outlined button — delegates to [OutlinedButton] with
/// app-themed styling.
class BrandOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const BrandOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.primary,
        side: BorderSide(color: palette.border, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: palette.primary,
        ),
      ),
    );
  }
}

/// Legacy filter chip.
class BrandChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const BrandChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? palette.primarySoft : palette.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? palette.primary : palette.border,
              width: selected ? 1.2 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? palette.primary : palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
