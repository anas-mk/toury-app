import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/router/app_router.dart';

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
        // Use goNamed to helperHome which is the root helper page, clearing the stack
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
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false, // Prevent going back to the interview
      child: Scaffold(
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Success Illustration ---
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceLG),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: Colors.green,
                    size: 80,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
                
                // --- Title ---
                Text(
                  'Interview Submitted!',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceMD),
                
                // --- Description ---
                Text(
                  'Your interview is now under review by our admin team. You will be notified once the review is complete.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceXL),
                
                // --- Automatic Redirection Info ---
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(height: AppTheme.spaceMD),
                Text(
                  'Returning to Home...',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
