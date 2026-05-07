import 'package:flutter/material.dart';
import '../../../../../../../core/widgets/app_empty_state.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(icon: icon, title: title, message: subtitle);
  }
}
