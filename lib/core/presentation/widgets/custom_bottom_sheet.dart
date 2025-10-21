import 'package:flutter/material.dart';

class CustomBottomSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? child;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool isDismissible;

  const CustomBottomSheet({
    super.key,
    this.title,
    this.subtitle,
    this.child,
    this.height,
    this.padding,
    this.isDismissible = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? subtitle,
    Widget? child,
    double? height,
    EdgeInsetsGeometry? padding,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomBottomSheet(
        title: title,
        subtitle: subtitle,
        height: height,
        padding: padding,
        isDismissible: isDismissible,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: height != null ? (height! / MediaQuery.of(context).size.height) : 0.45,
      minChildSize: 0.25,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
            ],
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              if (title != null) ...[
                Text(
                  title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],

              // Scrollable content
              if (child != null)
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    child: child!,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
