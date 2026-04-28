import 'package:flutter/material.dart';

import '../../theme/brand_tokens.dart';
import 'blob_clipper.dart';

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
    return SheetBlobShape(
      child: Container(
        color: BrandTokens.surfaceWhite,
        padding: const EdgeInsets.only(top: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            const SizedBox(height: 8),
            Padding(padding: padding, child: child),
            SizedBox(
              height: MediaQuery.of(context).viewInsets.bottom,
            ),
          ],
        ),
      ),
    );
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

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: BrandTokens.borderSoft,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
