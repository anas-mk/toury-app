import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/widgets/custom_button.dart';

class InterviewUnderReviewPage extends StatelessWidget {
  const InterviewUnderReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return AppScaffold(
      appBar: BasicAppBar(showBackButton: false, title: null, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageGutter,
            vertical: AppSpacing.lg,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 520;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(
                        narrow ? AppSpacing.xxl : AppSpacing.xxxl,
                      ),
                      decoration: BoxDecoration(
                        color: palette.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.hourglass_empty_rounded,
                        size: narrow ? 64 : 80,
                        color: palette.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Text(
                    'Interview submitted',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Your interview has been submitted and is currently under AI review. '
                    'You will be notified once the review is complete.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: palette.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  CustomButton(
                    text: 'Return home',
                    variant: ButtonVariant.primary,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRouter.helperHome);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
