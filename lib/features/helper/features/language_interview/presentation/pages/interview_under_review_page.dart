import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';

/// Post-submission "Under Review" screen.
///
/// Shown immediately after the helper finishes submitting their interview;
/// the back-end will notify them when the AI review completes.
class InterviewUnderReviewPage extends StatelessWidget {
  const InterviewUnderReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: palette.scaffold,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Spacer(),
                FadeInSlide(child: _Hero()),
                const SizedBox(height: 32),
                FadeInSlide(
                  delay: const Duration(milliseconds: 120),
                  child: _Title(),
                ),
                const SizedBox(height: 12),
                FadeInSlide(
                  delay: const Duration(milliseconds: 200),
                  child: _Body(),
                ),
                const SizedBox(height: 24),
                FadeInSlide(
                  delay: const Duration(milliseconds: 280),
                  child: _Timeline(),
                ),
                const Spacer(),
                FadeInSlide(
                  delay: const Duration(milliseconds: 360),
                  child: _PrimaryCTA(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _Hero extends StatefulWidget {
  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200 + (_ctrl.value * 12),
              height: 200 + (_ctrl.value * 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    palette.primary.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Container(
              width: 150 + (_ctrl.value * 8),
              height: 150 + (_ctrl.value * 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    palette.primary.withValues(alpha: 0.22),
                    palette.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [palette.primary, const Color(0xFF7B61FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.36),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Title / Body ────────────────────────────────────────────────────────────

class _Title extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    return Text(
      'Interview submitted',
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineSmall?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 24,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Text(
      'Your interview is now being reviewed by our AI. '
      "We'll notify you as soon as the review is complete.",
      textAlign: TextAlign.center,
      style: TextStyle(
        color: palette.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
    );
  }
}

// ─── Timeline ────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.of(context).border,
          width: 0.5,
        ),
      ),
      child: const Column(
        children: [
          _TimelineRow(
            icon: Icons.check_circle_rounded,
            label: 'Submitted',
            isDone: true,
            isFirst: true,
          ),
          _TimelineRow(
            icon: Icons.auto_awesome_rounded,
            label: 'AI review in progress',
            isDone: false,
            isCurrent: true,
          ),
          _TimelineRow(
            icon: Icons.notifications_active_rounded,
            label: "You'll be notified",
            isDone: false,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isFirst;
  final bool isLast;

  const _TimelineRow({
    required this.icon,
    required this.label,
    this.isDone = false,
    this.isCurrent = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    final color = isDone
        ? const Color(0xFF22C55E)
        : isCurrent
            ? palette.primary
            : palette.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isCurrent)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.14),
                  ),
                ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: isDone ? 1 : 0.16),
                  border: Border.all(
                    color: color.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 13,
                  color: isDone ? Colors.white : color,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDone
                    ? palette.textPrimary
                    : isCurrent
                        ? palette.textPrimary
                        : palette.textMuted,
                fontWeight: isCurrent || isDone
                    ? FontWeight.w700
                    : FontWeight.w500,
                fontSize: 13.5,
              ),
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'NOW',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── CTA ─────────────────────────────────────────────────────────────────────

class _PrimaryCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticService.light();
            context.go(AppRouter.helperHome);
          },
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [palette.primary, const Color(0xFF7B61FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.primary.withValues(alpha: 0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Return home',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
