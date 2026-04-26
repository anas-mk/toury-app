import 'package:flutter/material.dart';

class BasicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Color? backgroundColor;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final bool showBackButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const BasicAppBar({
    super.key,
    this.title,
    this.backgroundColor,
    this.iconColor,
    this.titleStyle,
    this.showBackButton = true,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      actions: actions,
      bottom: bottom,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: iconColor ?? theme.colorScheme.onSurface,
                size: 20,
              ),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      title: title != null
          ? Text(
              title!,
              style: titleStyle ??
                  theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: iconColor ?? theme.colorScheme.onSurface,
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
