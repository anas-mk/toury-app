import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/router/app_router.dart';
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
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<ExamsCubit, ExamsState>(
      listenWhen: (previous, current) => 
          previous.status != current.status || 
          previous.interview != current.interview,
      listener: (context, state) {
        if (state.status == ExamsStatus.interviewError && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.status == ExamsStatus.interviewStarted || 
                   state.status == ExamsStatus.interviewLoaded) {
          // POST-SUBMIT LOCK: Never navigate into interview flow after submission
          if (state.isInterviewLocked) return;

          if (state.interview != null && !state.isNavigating) {
            final cubit = context.read<ExamsCubit>();
            cubit.setNavigating(true);
            
            final needsPreInterview = state.interview!.id != state.completedPreInterviewId;
            
            // Navigate by path only — no extra needed (cubit is singleton in GetIt)
            if (needsPreInterview) {
              context.push(AppRouter.preInterview);
            } else {
              context.push(AppRouter.interviewScreen);
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Language Interviews'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          foregroundColor: isDark ? Colors.white : Colors.black87,
        ),
        body: BlocBuilder<ExamsCubit, ExamsState>(
          builder: (context, state) {
            if (state.status == ExamsStatus.interviewLoading && state.languages.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.languages.isEmpty) {
              return _buildEmptyState(theme, isDark);
            }

            return RefreshIndicator(
              onRefresh: () => context.read<ExamsCubit>().getLanguages(),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                itemCount: state.languages.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spaceMD),
                itemBuilder: (context, index) {
                  final lang = state.languages[index];
                  return _LanguageCard(language: lang);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: AppTheme.spaceMD),
          const Text('No language interviews available', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final dynamic language;

  const _LanguageCard({required this.language});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasCooldown = language.nextEligibleTestAt != null;
    final canStart = language.canStartInterview;
    final isContinuing = language.activeInterviewId != null;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowLight(context),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSM),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              language.code,
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (hasCooldown)
                  Text(
                    'Retake available on: ${language.nextEligibleTestAt}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.orangeAccent),
                  )
                else
                  Text(
                    language.verificationStatus ?? 'Click to start interview',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          _buildActionButton(context, theme, canStart, isContinuing, hasCooldown),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ThemeData theme, bool canStart, bool isContinuing, bool hasCooldown) {
    final compactStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(80, 40),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
    );

    final compactOutlinedStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(80, 40),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
    );

    if (isContinuing) {
      return ElevatedButton(
        onPressed: () => context.read<ExamsCubit>().loadInterview(language.activeInterviewId!),
        style: compactStyle,
        child: const Text('Continue'),
      );
    }

    if (canStart) {
      return ElevatedButton(
        onPressed: () => context.read<ExamsCubit>().startInterview(language.code),
        style: compactStyle,
        child: const Text('Start'),
      );
    }

    return OutlinedButton(
      onPressed: null,
      style: compactOutlinedStyle,
      child: Text(hasCooldown ? 'Locked' : 'Done'),
    );
  }
}
