import 'package:flutter/material.dart';

import '../../theme/app_color.dart';

class BasicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Color backgroundColor;
  final Color iconColor;
  final TextStyle? titleStyle;

  const BasicAppBar({
    super.key,
    this.title,
    this.backgroundColor = AppColor.primaryColor,
    this.iconColor = Colors.white,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: iconColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: title != null
          ? Text(
        title!,
        style: titleStyle ??
            TextStyle(
              color: iconColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
      )
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
