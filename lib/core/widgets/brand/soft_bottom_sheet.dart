import 'package:flutter/material.dart';

import '../custom_bottom_sheet.dart';

// Modern bottom sheet with drag handle and the same blob top edge as
// the hero header. Use the static [show] helper as a drop-in replacement
// for `showModalBottomSheet`.
class SoftBottomSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SoftBottomSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 24),
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(padding: padding, child: child);
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (_) => SoftBottomSheet(child: child),
    );
  }
}
