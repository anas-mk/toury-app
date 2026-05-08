// Modern booking status banner with a tinted gradient strip on the left and
// an animated pulsing dot when the trip is currently active.

import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_dimens.dart';

class BookingStatusBanner extends StatelessWidget {
  final String status;
  const BookingStatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final info = _info(status, palette);

    return Container(
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: palette.isDark ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: info.color.withValues(alpha: 0.22)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    info.color,
                    Color.lerp(info.color, Colors.black, 0.30)!,
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md + 2,
                ),
                child: Row(
                  children: [
                    _StatusIcon(
                      icon: info.icon,
                      color: info.color,
                      pulse: info.pulse,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            info.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: info.color,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            info.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusInfo _info(String s, AppColors palette) {
    switch (s.toLowerCase()) {
      case 'pending':
      case 'pendinghelperresponse':
        return _StatusInfo(
          color: palette.warning,
          title: 'Pending Your Response',
          subtitle: 'Accept or decline the request to continue.',
          icon: Icons.hourglass_empty_rounded,
          pulse: true,
        );
      case 'accepted':
      case 'acceptedbyhelper':
      case 'confirmed':
      case 'confirmedpaid':
        return _StatusInfo(
          color: palette.primary,
          title: 'Confirmed & Upcoming',
          subtitle: 'Trip is locked. Get ready when traveler is ready.',
          icon: Icons.check_circle_outline_rounded,
        );
      case 'inprogress':
      case 'started':
      case 'active':
        return _StatusInfo(
          color: palette.success,
          title: 'Trip In Progress',
          subtitle: 'Live tracking is active. Drive safe.',
          icon: Icons.navigation_rounded,
          pulse: true,
        );
      case 'completed':
        return _StatusInfo(
          color: palette.textMuted,
          title: 'Trip Completed',
          subtitle: 'Payout secured. Thanks for the great service.',
          icon: Icons.done_all_rounded,
        );
      case 'cancelled':
      case 'cancelledbyhelper':
      case 'cancelledbytraveler':
      case 'cancelledbyadmin':
        return _StatusInfo(
          color: palette.danger,
          title: 'Cancelled',
          subtitle: 'This booking has been closed.',
          icon: Icons.cancel_outlined,
        );
      case 'rejected':
      case 'declinedbyhelper':
        return _StatusInfo(
          color: palette.danger,
          title: 'Request Declined',
          subtitle: 'No further action needed.',
          icon: Icons.block_rounded,
        );
      default:
        return _StatusInfo(
          color: palette.textMuted,
          title: s,
          subtitle: '',
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _StatusInfo {
  final Color color;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool pulse;

  _StatusInfo({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.pulse = false,
  });
}

class _StatusIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool pulse;
  const _StatusIcon({
    required this.icon,
    required this.color,
    required this.pulse,
  });

  @override
  State<_StatusIcon> createState() => _StatusIconState();
}

class _StatusIconState extends State<_StatusIcon>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medallion = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.20),
        shape: BoxShape.circle,
      ),
      child: Icon(widget.icon, color: widget.color, size: 18),
    );

    if (_ctrl == null) return medallion;

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl!,
            builder: (_, __) {
              final t = _ctrl!.value;
              return Container(
                width: 36 + 8 * t,
                height: 36 + 8 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.30 * (1 - t)),
                ),
              );
            },
          ),
          medallion,
        ],
      ),
    );
  }
}
