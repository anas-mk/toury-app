import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../data/models/language_model.dart';
import '../cubit/exams_cubit.dart';
import '../cubit/exams_state.dart';

/// Helper-side language interview hub.
///
/// Shows the helper's languages and the verification status of each, plus a
/// "Start interview" CTA when the backend allows it (`canStartInterview`).
///
/// This screen lives behind the **Language** tab of the helper bottom-nav.
class ExamsPage extends StatelessWidget {
  const ExamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<ExamsCubit>()..getLanguages(),
      child: const _ExamsPageView(),
    );
  }
}

class _ExamsPageView extends StatelessWidget {
  const _ExamsPageView();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return BlocListener<ExamsCubit, ExamsState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.interview != current.interview,
      listener: _handleStateTransitions,
      child: Scaffold(
        backgroundColor: palette.scaffold,
        body: BlocBuilder<ExamsCubit, ExamsState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: palette.primary,
              onRefresh: () => context.read<ExamsCubit>().getLanguages(),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  const SliverToBoxAdapter(child: _HeroHeader()),
                  if (state.languages.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _StatsStrip(languages: state.languages),
                    ),
                  _buildBody(context, state),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleStateTransitions(BuildContext context, ExamsState state) {
    if (state.status == ExamsStatus.interviewError &&
        state.errorMessage != null &&
        state.languages.isNotEmpty) {
      AppSnackbar.error(context, state.errorMessage!);
      return;
    }

    if (state.status == ExamsStatus.interviewStarted ||
        state.status == ExamsStatus.interviewLoaded) {
      if (state.isInterviewLocked) return;
      if (state.interview == null || state.isNavigating) return;

      final cubit = context.read<ExamsCubit>();
      cubit.setNavigating(true);

      final needsPreInterview =
          state.interview!.id != state.completedPreInterviewId;
      if (needsPreInterview) {
        context.push(AppRouter.preInterview);
      } else {
        context.push(AppRouter.interviewScreen);
      }
    }
  }

  Widget _buildBody(BuildContext context, ExamsState state) {
    if (state.status == ExamsStatus.interviewLoading &&
        state.languages.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AppLoading(message: 'Loading languages…'),
      );
    }

    if (state.status == ExamsStatus.interviewError &&
        state.languages.isEmpty &&
        state.errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorState(
          title: 'Could not load interviews',
          message: state.errorMessage,
          onRetry: () => context.read<ExamsCubit>().getLanguages(),
        ),
      );
    }

    if (state.languages.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          icon: Icons.translate_rounded,
          title: 'No interviews available',
          message:
              'When language interviews are enabled for your account, they will appear here.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverList.separated(
        itemCount: state.languages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return FadeInSlide(
            delay: Duration(milliseconds: 60 * index),
            child: _LanguageCard(language: state.languages[index]),
          );
        },
      ),
    );
  }
}

// ─── Hero Header ─────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.isDark
                  ? const [Color(0xFF1B2046), Color(0xFF3A2360)]
                  : [palette.primary, const Color(0xFF7B61FF)],
            ),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(
                  alpha: palette.isDark ? 0.18 : 0.30,
                ),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -28,
                right: -28,
                child: _Orb(
                  size: 110,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              Positioned(
                bottom: -36,
                right: 60,
                child: _Orb(
                  size: 70,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 0.6,
                      ),
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Language Interviews',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verify the languages you speak to unlock more bookings',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ─── Stats Strip ─────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final List<LanguageModel> languages;

  const _StatsStrip({required this.languages});

  @override
  Widget build(BuildContext context) {
    final verifiedCount = languages.where((l) => l.isVerified).length;
    final pendingCount =
        languages.where((l) => !l.isVerified && l.activeInterviewId != null)
            .length;
    final availableCount = languages.where((l) => l.canStartInterview).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.verified_rounded,
              label: 'Verified',
              value: '$verifiedCount',
              color: const Color(0xFF22C55E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.hourglass_top_rounded,
              label: 'Pending',
              value: '$pendingCount',
              color: const Color(0xFFFFB020),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.play_circle_rounded,
              label: 'Available',
              value: '$availableCount',
              color: const Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: palette.isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    fontSize: 15,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Language Card ───────────────────────────────────────────────────────────

class _LanguageCard extends StatelessWidget {
  final LanguageModel language;
  const _LanguageCard({required this.language});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    final isContinuing = language.activeInterviewId != null;
    final canStart = language.canStartInterview;
    final hasCooldown = language.nextEligibleTestAt != null;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: palette.isDark ? 0.20 : 0.04,
            ),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LanguageBadge(code: language.code),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              language.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: palette.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (language.isNative) ...[
                            const SizedBox(width: 6),
                            _MetaChip(
                              icon: Icons.flag_rounded,
                              label: 'Native',
                              color: const Color(0xFF6366F1),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusLine(),
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatusPill(language: language),
                const Spacer(),
                _ActionButton(
                  language: language,
                  isContinuing: isContinuing,
                  canStart: canStart,
                  hasCooldown: hasCooldown,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLine() {
    if (language.nextEligibleTestAt != null) {
      return 'Retake available: ${language.nextEligibleTestAt}';
    }
    if (language.activeInterviewId != null) {
      return 'In progress — finish your interview to get verified';
    }
    if (language.isVerified) {
      final level = language.level;
      return level != null
          ? 'Verified at level $level'
          : 'Verified speaker';
    }
    if (language.canStartInterview) {
      return 'Tap "Start" to begin a 3-question interview';
    }
    return language.verificationStatus ?? 'No interview available';
  }
}

class _LanguageBadge extends StatelessWidget {
  final String code;
  const _LanguageBadge({required this.code});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary.withValues(alpha: 0.18),
            const Color(0xFF7B61FF).withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: palette.primary.withValues(alpha: 0.22),
          width: 0.6,
        ),
      ),
      child: Center(
        child: Text(
          code.toUpperCase(),
          style: TextStyle(
            color: palette.primary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final LanguageModel language;
  const _StatusPill({required this.language});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    final IconData icon;
    final String label;
    final Color color;

    if (language.isVerified) {
      icon = Icons.verified_rounded;
      label = language.level != null ? language.level! : 'Verified';
      color = const Color(0xFF22C55E);
    } else if (language.activeInterviewId != null) {
      icon = Icons.hourglass_top_rounded;
      label = 'In progress';
      color = const Color(0xFFFFB020);
    } else if (language.nextEligibleTestAt != null) {
      icon = Icons.lock_clock_rounded;
      label = 'Cooldown';
      color = palette.warning;
    } else if (language.canStartInterview) {
      icon = Icons.play_circle_outline_rounded;
      label = 'Available';
      color = const Color(0xFF6366F1);
    } else {
      icon = Icons.do_not_disturb_alt_rounded;
      label = language.verificationStatus ?? 'Locked';
      color = palette.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final LanguageModel language;
  final bool isContinuing;
  final bool canStart;
  final bool hasCooldown;

  const _ActionButton({
    required this.language,
    required this.isContinuing,
    required this.canStart,
    required this.hasCooldown,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    if (!isContinuing && !canStart) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border, width: 0.6),
        ),
        child: Text(
          hasCooldown ? 'Locked' : 'Done',
          style: TextStyle(
            color: palette.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      );
    }

    final label = isContinuing ? 'Continue' : 'Start';
    final icon = isContinuing
        ? Icons.play_arrow_rounded
        : Icons.start_rounded;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticService.medium();
          final cubit = context.read<ExamsCubit>();
          if (isContinuing) {
            cubit.loadInterview(language.activeInterviewId!);
          } else {
            cubit.startInterview(language.code);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                palette.primary,
                const Color(0xFF7B61FF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: 0.32),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
