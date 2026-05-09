import 'package:flutter/material.dart';
import '../app_section_header.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
      padding: padding,
    );
  }
}
