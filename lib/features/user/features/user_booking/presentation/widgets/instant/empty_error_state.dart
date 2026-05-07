import 'package:flutter/material.dart';

import '../../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../../core/widgets/app_error_state.dart';

/// Reusable empty-state widget. Used when a list is empty (no helpers, no
/// alternatives, no chat messages, etc.).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// Full-page error state with a retry button.
class ErrorRetryState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const ErrorRetryState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      message: message,
      retryLabel: retryLabel,
      onRetry: onRetry,
    );
  }
}
