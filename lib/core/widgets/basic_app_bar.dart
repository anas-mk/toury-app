import 'package:flutter/material.dart';

class BasicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Color? backgroundColor;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final bool showBackButton;

  const BasicAppBar({
    super.key,
    this.title,
    this.backgroundColor,
    this.iconColor,
    this.titleStyle,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarTheme = theme.appBarTheme;

    final bgColor = backgroundColor ??
        appBarTheme.backgroundColor ??
        (isDark ? theme.colorScheme.surface : Colors.white);

    final icColor = iconColor ??
        appBarTheme.foregroundColor ??
        (isDark ? Colors.white : Colors.black87);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: bgColor,
      elevation: appBarTheme.elevation ?? (isDark ? 0 : 2),
      shadowColor:
      isDark ? Colors.transparent : Colors.black.withOpacity(0.1),
      centerTitle: appBarTheme.centerTitle ?? true,
      leading: showBackButton
          ? IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: icColor),
        onPressed: () => Navigator.pop(context),
      )
          : null,
      title: title != null
          ? Text(
        title!,
        style: titleStyle ??
            theme.textTheme.titleMedium?.copyWith(
              color: icColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      )
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
