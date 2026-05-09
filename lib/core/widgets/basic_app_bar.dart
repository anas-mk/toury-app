// lib/core/widgets/basic_app_bar.dart
//
// Standard app bar used by every page that doesn't need a custom hero
// header. Replaces the previous transparent variant with a theme-aware
// version that picks scaffold/surface colors automatically and uses
// chevron-style back navigation consistent with the rest of the app.

import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';

class BasicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Color? backgroundColor;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final bool showBackButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final Widget? leading;
  final double? elevation;

  const BasicAppBar({
    super.key,
    this.title,
    this.backgroundColor,
    this.iconColor,
    this.titleStyle,
    this.showBackButton = true,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.leading,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final fg = iconColor ?? palette.textPrimary;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor ?? Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      actions: actions,
      bottom: bottom,
      leading: leading ??
          (showBackButton && Navigator.of(context).canPop()
              ? IconButton(
                  splashRadius: 20,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: fg,
                    size: AppSize.iconMd,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                )
              : null),
      title: title != null
          ? Text(
              title!,
              style: titleStyle ??
                  theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
