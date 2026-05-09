import 'package:flutter/material.dart';

import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../domain/entities/booking_status.dart';

/// Phase 5 \u2014 vertical timeline that visualises a Scheduled booking's
/// life-cycle for the user.
///
/// We render a fixed sequence of HAPPY-PATH steps (Requested \u2192 Accepted
/// \u2192 Confirmed \u2192 Upcoming \u2192 In progress \u2192 Completed). Each
/// step is rendered as one of three states:
///
///   * `done`    \u2014 the booking has already passed this step.
///   * `current` \u2014 the booking is currently on this step.
///   * `pending` \u2014 future step (not yet reached).
///
/// Cancelled / declined / expired statuses short-circuit the timeline
/// and replace the latest step with a red "Cancelled" / "Declined" cap.
class StatusTimeline extends StatelessWidget {
  final BookingStatus status;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? confirmedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  const StatusTimeline({
    super.key,
    required this.status,
    this.createdAt,
    this.acceptedAt,
    this.confirmedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final isLast = i == steps.length - 1;
        return _TimelineStep(step: steps[i], isLast: isLast);
      }),
    );
  }

  List<_StepData> _buildSteps() {
    if (status.isCancelled) {
      return [
        _StepData(
          title: 'Booked',
          subtitle: _format(createdAt),
          state: _StepState.done,
          icon: Icons.event_note_rounded,
        ),
        _StepData(
          title: 'Cancelled',
          subtitle: cancellationReason ?? _format(cancelledAt),
          state: _StepState.cancelled,
          icon: Icons.cancel_rounded,
        ),
      ];
    }

    final completed = _CompletionMap(status);

    return [
      _StepData(
        title: 'Booking requested',
        subtitle: _format(createdAt),
        state: completed.requested,
        icon: Icons.event_note_rounded,
      ),
      _StepData(
        title: 'Helper accepted',
        subtitle: _format(acceptedAt),
        state: completed.accepted,
        icon: Icons.person_pin_rounded,
      ),
      _StepData(
        title: 'Booking confirmed',
        subtitle: _format(confirmedAt),
        state: completed.confirmed,
        icon: Icons.check_circle_rounded,
      ),
      _StepData(
        title: 'Trip in progress',
        subtitle: _format(startedAt),
        state: completed.inProgress,
        icon: Icons.directions_walk_rounded,
      ),
      _StepData(
        title: 'Trip completed',
        subtitle: _format(completedAt),
        state: completed.completed,
        icon: Icons.flag_rounded,
      ),
    ];
  }

  String? _format(DateTime? dt) {
    if (dt == null) return null;
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[local.month - 1]} ${local.day} \u2022 $h:$m';
  }
}

class _CompletionMap {
  final _StepState requested;
  final _StepState accepted;
  final _StepState confirmed;
  final _StepState inProgress;
  final _StepState completed;

  factory _CompletionMap(BookingStatus s) {
    switch (s) {
      case BookingStatus.pendingHelperResponse:
      case BookingStatus.reassignmentInProgress:
      case BookingStatus.waitingForUserAction:
      case BookingStatus.declinedByHelper:
      case BookingStatus.expiredNoResponse:
        return const _CompletionMap._(
          requested: _StepState.current,
          accepted: _StepState.pending,
          confirmed: _StepState.pending,
          inProgress: _StepState.pending,
          completed: _StepState.pending,
        );
      case BookingStatus.acceptedByHelper:
        return const _CompletionMap._(
          requested: _StepState.done,
          accepted: _StepState.current,
          confirmed: _StepState.pending,
          inProgress: _StepState.pending,
          completed: _StepState.pending,
        );
      case BookingStatus.confirmedAwaitingPayment:
      case BookingStatus.confirmedPaid:
        return const _CompletionMap._(
          requested: _StepState.done,
          accepted: _StepState.done,
          confirmed: _StepState.current,
          inProgress: _StepState.pending,
          completed: _StepState.pending,
        );
      case BookingStatus.upcoming:
        return const _CompletionMap._(
          requested: _StepState.done,
          accepted: _StepState.done,
          confirmed: _StepState.done,
          inProgress: _StepState.pending,
          completed: _StepState.pending,
        );
      case BookingStatus.inProgress:
        return const _CompletionMap._(
          requested: _StepState.done,
          accepted: _StepState.done,
          confirmed: _StepState.done,
          inProgress: _StepState.current,
          completed: _StepState.pending,
        );
      case BookingStatus.completed:
        return const _CompletionMap._(
          requested: _StepState.done,
          accepted: _StepState.done,
          confirmed: _StepState.done,
          inProgress: _StepState.done,
          completed: _StepState.done,
        );
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByHelper:
      case BookingStatus.cancelledBySystem:
      case BookingStatus.unknown:
        return const _CompletionMap._(
          requested: _StepState.done,
          accepted: _StepState.pending,
          confirmed: _StepState.pending,
          inProgress: _StepState.pending,
          completed: _StepState.pending,
        );
    }
  }

  const _CompletionMap._({
    required this.requested,
    required this.accepted,
    required this.confirmed,
    required this.inProgress,
    required this.completed,
  });
}

enum _StepState { done, current, pending, cancelled }

class _StepData {
  final String title;
  final String? subtitle;
  final _StepState state;
  final IconData icon;
  const _StepData({
    required this.title,
    this.subtitle,
    required this.state,
    required this.icon,
  });
}

class _TimelineStep extends StatelessWidget {
  final _StepData step;
  final bool isLast;

  const _TimelineStep({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final palette = _palette(step.state);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border, width: 2),
                ),
                child: Icon(step.icon, color: palette.fg, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: step.state == _StepState.done
                        ? BrandTokens.primaryBlue
                        : BrandTokens.borderSoft,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: BrandTypography.body(
                      weight: step.state == _StepState.current
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: step.state == _StepState.pending
                          ? BrandTokens.textMuted
                          : BrandTokens.textPrimary,
                    ),
                  ),
                  if (step.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.subtitle!,
                      style: BrandTypography.caption(
                        color: step.state == _StepState.cancelled
                            ? BrandTokens.dangerRed
                            : BrandTokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({Color fg, Color bg, Color border}) _palette(_StepState s) {
    switch (s) {
      case _StepState.done:
        return (
          fg: Colors.white,
          bg: BrandTokens.primaryBlue,
          border: BrandTokens.primaryBlue,
        );
      case _StepState.current:
        return (
          fg: BrandTokens.primaryBlue,
          bg: BrandTokens.borderTinted,
          border: BrandTokens.primaryBlue,
        );
      case _StepState.pending:
        return (
          fg: BrandTokens.textMuted,
          bg: BrandTokens.surfaceWhite,
          border: BrandTokens.borderSoft,
        );
      case _StepState.cancelled:
        return (
          fg: Colors.white,
          bg: BrandTokens.dangerRed,
          border: BrandTokens.dangerRed,
        );
    }
  }
}
