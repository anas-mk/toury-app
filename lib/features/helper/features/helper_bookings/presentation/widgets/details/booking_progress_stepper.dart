// Modern horizontal trip-progress stepper used at the top of the booking
// details page. Renders four steps (Pending → Confirmed → In Progress →
// Completed) with the current stage highlighted using the brand gradient.

import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_dimens.dart';
import '../../../domain/entities/helper_booking_entities.dart';
import '../../../domain/entities/helper_booking_status_x.dart';

class BookingProgressStepper extends StatelessWidget {
  final HelperBooking booking;
  const BookingProgressStepper({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final stage = _stage();
    final isCancelled = booking.isCancelled;

    final steps = <_Step>[
      _Step(label: 'Requested', icon: Icons.flag_outlined),
      _Step(label: 'Confirmed', icon: Icons.check_circle_outline_rounded),
      _Step(label: 'In Progress', icon: Icons.navigation_rounded),
      _Step(label: 'Completed', icon: Icons.flag_circle_rounded),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.30 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Journey',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (ctx, constraints) {
              return Row(
                children: List.generate(steps.length * 2 - 1, (index) {
                  if (index.isOdd) {
                    final beforeIdx = index ~/ 2;
                    final filled = beforeIdx < stage && !isCancelled;
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: filled
                              ? LinearGradient(
                                  colors: [
                                    palette.primary,
                                    palette.primaryStrong,
                                  ],
                                )
                              : null,
                          color:
                              filled ? null : palette.border.withValues(
                                alpha: 0.6,
                              ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }
                  final stepIdx = index ~/ 2;
                  final step = steps[stepIdx];
                  final isCurrent = stepIdx == stage && !isCancelled;
                  final isDone = stepIdx < stage && !isCancelled;
                  return _StepDot(
                    icon: step.icon,
                    isCurrent: isCurrent,
                    isDone: isDone,
                    isCancelled: isCancelled,
                  );
                }),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (i) {
              final isCurrent = i == stage && !isCancelled;
              return SizedBox(
                width: 70,
                child: Text(
                  steps[i].label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isCurrent
                        ? palette.primary
                        : palette.textMuted,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              );
            }),
          ),
          if (isCancelled) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: palette.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: palette.danger.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    color: palette.danger,
                    size: AppSize.iconSm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'This booking was cancelled.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _stage() {
    if (booking.isCompleted) return 3;
    if (booking.isActive) return 2;
    if (booking.isConfirmed) return 1;
    return 0;
  }
}

class _Step {
  final String label;
  final IconData icon;
  _Step({required this.label, required this.icon});
}

class _StepDot extends StatelessWidget {
  final IconData icon;
  final bool isCurrent;
  final bool isDone;
  final bool isCancelled;

  const _StepDot({
    required this.icon,
    required this.isCurrent,
    required this.isDone,
    required this.isCancelled,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    if (isCancelled) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: palette.danger.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: palette.danger.withValues(alpha: 0.32)),
        ),
        child: Icon(Icons.close_rounded, size: 16, color: palette.danger),
      );
    }

    if (isCurrent) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.primary, palette.primaryStrong],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      );
    }
    if (isDone) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: palette.primary.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, color: palette.primary, size: 16),
      );
    }
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: palette.surfaceInset,
        shape: BoxShape.circle,
        border: Border.all(color: palette.border),
      ),
      child: Icon(icon, color: palette.textMuted, size: 14),
    );
  }
}
