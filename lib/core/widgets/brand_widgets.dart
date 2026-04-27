import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/brand_tokens.dart';

/// Section heading using [BrandTokens] typography colors (no raw hex in pages).
class BrandSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const BrandSectionTitle(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: BrandTokens.textPrimary,
          ),
        ),
        if ((subtitle ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: BrandTokens.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

/// Card shell: surface, border, and soft shadow from [BrandTokens].
class BrandCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const BrandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spaceMD),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: BrandTokens.borderSoft),
        boxShadow: [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Primary filled button on the RAFIQ blue gradient.
class BrandPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onPressed;
  /// When `false`, the button looks muted but may still receive [onPressed].
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
    final interactive = onPressed != null && !isLoading;
    final muted = interactive && !visualEnabled;
    return Opacity(
      opacity: isLoading ? 1.0 : (muted ? 0.55 : 1.0),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          gradient: const LinearGradient(
            colors: [
              BrandTokens.primaryBlue,
              BrandTokens.primaryBlueDark,
            ],
          ),
          boxShadow: (interactive && visualEnabled)
              ? [
                  BoxShadow(
                    color: BrandTokens.primaryBlue.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            onTap: interactive ? onPressed : null,
            child: Center(
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
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined action using brand blues.
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
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: BrandTokens.primaryBlue,
        side: const BorderSide(color: BrandTokens.borderSoft, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLG,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

/// Small tonal chip for filters or metadata.
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? BrandTokens.primaryBlue.withValues(alpha: 0.12)
                : BrandTokens.bgSoft,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
              color: selected ? BrandTokens.primaryBlue : BrandTokens.borderSoft,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? BrandTokens.primaryBlue : BrandTokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}