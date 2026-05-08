import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_scaffold.dart';

class InterviewPendingScreen extends StatefulWidget {
  const InterviewPendingScreen({super.key});

  @override
  State<InterviewPendingScreen> createState() => _InterviewPendingScreenState();
}

class _InterviewPendingScreenState extends State<InterviewPendingScreen> {
  bool _isRedirecting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startRedirectionTimer();
  }

  void _startRedirectionTimer() {
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isRedirecting) {
        _isRedirecting = true;
        context.go(AppRouter.helperHome);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return PopScope(
      canPop: false,
      child: AppScaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageGutter,
                  vertical: AppSpacing.xxl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      decoration: BoxDecoration(
                        color: palette.successSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_read_rounded,
                        color: palette.success,
                        size: 72,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Interview submitted',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Your interview is under review. You will be notified when the review is complete.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    const AppSpinner.large(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Returning to home…',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
