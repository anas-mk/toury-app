import 'package:flutter/material.dart';

class BasicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Color? backgroundColor;
  final Color? iconColor;
  final TextStyle? titleStyle;

  const BasicAppBar({
    super.key,
    this.title,
    this.backgroundColor,
    this.iconColor,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;

    final bgColor = backgroundColor ?? appBarTheme.backgroundColor ?? theme.colorScheme.surface;
    final icColor = iconColor ?? appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;

    return AppBar(
      backgroundColor: bgColor,
      elevation: appBarTheme.elevation ?? 0,
      centerTitle: appBarTheme.centerTitle ?? true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: icColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: title != null
          ? Text(
        title!,
        style: titleStyle ??
            theme.textTheme.titleMedium?.copyWith(
              color: icColor,
              fontWeight: FontWeight.bold,
            ),
      )
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
