import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';

class InterviewUnderReviewPage extends StatelessWidget {
  const InterviewUnderReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.hourglass_empty_rounded,
                size: 100,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppTheme.spaceXL),
              Text(
                'Interview Submitted',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Text(
                'Your interview has been submitted and is currently under AI review. You will be notified once the review is complete.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const Spacer(),
              CustomButton(
                text: 'Return Home',
                variant: ButtonVariant.primary,
                onPressed: () {
                  // Navigating to the home tab or route explicitly depending on architecture
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/helper/home');
                  }
                },
              ),
              const SizedBox(height: AppTheme.spaceXL),
            ],
          ),
        ),
      ),
    );
  }
}
