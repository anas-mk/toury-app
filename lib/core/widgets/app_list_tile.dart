// lib/core/widgets/app_list_tile.dart
//
// Polished list tile for settings rows, account menu items, and any
// list-of-actions surface. Supports leading icon, optional trailing
// arrow/badge/value, danger styling, and switch toggle mode.

import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';

class AppListTile extends StatelessWidget {
  final IconData? leadingIcon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dangerous;
  final bool showChevron;
  final EdgeInsetsGeometry padding;

  const AppListTile({
    super.key,
    required this.title,
    this.leadingIcon,
    this.leading,
    this.subtitle,
    this.trailingText,
    this.trailing,
    this.onTap,
    this.dangerous = false,
    this.showChevron = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    final accent = dangerous ? palette.danger : palette.primary;
    final accentSoft = dangerous ? palette.dangerSoft : palette.primarySoft;
    final titleColor = dangerous ? palette.danger : palette.textPrimary;

    final leadingWidget = leading ??
        (leadingIcon != null
            ? Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  leadingIcon,
                  color: accent,
                  size: AppSize.iconMd,
                ),
              )
            : null);

    Widget? trailingWidget = trailing;
    if (trailingWidget == null) {
      if (trailingText != null) {
        trailingWidget = Text(
          trailingText!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        );
      } else if (onTap != null && showChevron) {
        trailingWidget = Icon(
          Icons.chevron_right_rounded,
          color: palette.textMuted,
          size: AppSize.iconLg,
        );
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              if (leadingWidget != null) ...[
                leadingWidget,
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailingWidget,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Group multiple [AppListTile]s into a single rounded surface with
/// dividers between rows.
class AppListGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final String? title;

  const AppListGroup({
    super.key,
    required this.children,
    this.title,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final separated = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      separated.add(children[i]);
      if (i != children.length - 1) {
        separated.add(Divider(
          height: 1,
          thickness: 1,
          color: palette.divider,
          indent: 60,
          endIndent: AppSpacing.md,
        ));
      }
    }

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                title!.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: palette.border),
            ),
            child: Column(children: separated),
          ),
        ],
      ),
    );
  }
}
