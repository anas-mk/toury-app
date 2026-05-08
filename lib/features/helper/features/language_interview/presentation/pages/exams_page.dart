import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../data/models/language_model.dart';
import '../cubit/exams_cubit.dart';
import '../cubit/exams_state.dart';

class ExamsPage extends StatelessWidget {
  const ExamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      // Use the singleton from GetIt — same instance shared with interview screens
      value: sl<ExamsCubit>()..getLanguages(),
      child: const _ExamsPageView(),
    );
  }
}

class _ExamsPageView extends StatelessWidget {
  const _ExamsPageView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return BlocListener<ExamsCubit, ExamsState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.interview != current.interview,
      listener: (context, state) {
        if (state.status == ExamsStatus.interviewError &&
            state.errorMessage != null) {
          // Inline error handles initial empty-list failures; toast for in-flow errors only.
          if (state.languages.isNotEmpty) {
            AppSnackbar.error(context, state.errorMessage!);
          }
        } else if (state.status == ExamsStatus.interviewStarted ||
            state.status == ExamsStatus.interviewLoaded) {
          // POST-SUBMIT LOCK: Never navigate into interview flow after submission
          if (state.isInterviewLocked) return;

          if (state.interview != null && !state.isNavigating) {
            final cubit = context.read<ExamsCubit>();
            cubit.setNavigating(true);

            final needsPreInterview =
                state.interview!.id != state.completedPreInterviewId;

            // Navigate by path only — no extra needed (cubit is singleton in GetIt)
            if (needsPreInterview) {
              context.push(AppRouter.preInterview);
            } else {
              context.push(AppRouter.interviewScreen);
            }
          }
        }
      },
      child: AppScaffold(
        appBar: AppBar(
          title: Text(
            'Language Interviews',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          foregroundColor: palette.textPrimary,
        ),
        body: BlocBuilder<ExamsCubit, ExamsState>(
          builder: (context, state) {
            if (state.status == ExamsStatus.interviewLoading &&
                state.languages.isEmpty) {
              return const AppLoading(message: 'Loading languages…');
            }

            if (state.status == ExamsStatus.interviewError &&
                state.languages.isEmpty &&
                state.errorMessage != null) {
              return AppErrorState(
                title: 'Could not load interviews',
                message: state.errorMessage,
                onRetry: () => context.read<ExamsCubit>().getLanguages(),
              );
            }

            if (state.languages.isEmpty) {
              return AppEmptyState(
                icon: Icons.translate_rounded,
                title: 'No language interviews available',
                message:
                    'When interviews are enabled for your account, they will appear here.',
              );
            }

            return RefreshIndicator(
              color: palette.primary,
              onRefresh: () => context.read<ExamsCubit>().getLanguages(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageGutter,
                  vertical: AppSpacing.lg,
                ),
                itemCount: state.languages.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  return _LanguageCard(language: state.languages[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final LanguageModel language;

  const _LanguageCard({required this.language});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    final hasCooldown = language.nextEligibleTestAt != null;
    final canStart = language.canStartInterview;
    final isContinuing = language.activeInterviewId != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.border.withValues(alpha: 0.35)),
        boxShadow: AppTheme.shadowLight(context),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: palette.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              language.code,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (hasCooldown)
                  Text(
                    'Retake available: ${language.nextEligibleTestAt}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    language.verificationStatus ??
                        'Tap to start your interview',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildActionButton(context, canStart, isContinuing, hasCooldown),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    bool canStart,
    bool isContinuing,
    bool hasCooldown,
  ) {
    final compactFilled = FilledButton.styleFrom(
      minimumSize: const Size(88, AppSize.buttonSm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      visualDensity: VisualDensity.compact,
    );

    final compactOutlined = OutlinedButton.styleFrom(
      minimumSize: const Size(88, AppSize.buttonSm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      visualDensity: VisualDensity.compact,
    );

    if (isContinuing) {
      return FilledButton(
        onPressed: () => context.read<ExamsCubit>().loadInterview(
          language.activeInterviewId!,
        ),
        style: compactFilled,
        child: const Text('Continue'),
      );
    }

    if (canStart) {
      return FilledButton(
        onPressed: () =>
            context.read<ExamsCubit>().startInterview(language.code),
        style: compactFilled,
        child: const Text('Start'),
      );
    }

    return OutlinedButton(
      onPressed: null,
      style: compactOutlined,
      child: Text(hasCooldown ? 'Locked' : 'Done'),
    );
  }
}
