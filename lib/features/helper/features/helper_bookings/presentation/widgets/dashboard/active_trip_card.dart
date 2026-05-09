import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/utils/currency_format.dart';
import '../../../domain/entities/helper_booking_entities.dart';

/// Modern active trip card with glass status badge, prominent traveler info,
/// route summary and primary action buttons.
class ActiveTripCard extends StatelessWidget {
  final HelperBooking booking;

  const ActiveTripCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final s = booking.status.toLowerCase();
    final canChat = ['accepted', 'confirmed', 'inprogress', 'started']
        .contains(s);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            context.push(AppRouter.helperActiveBooking, extra: booking.id),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.isDark
                  ? [
                      palette.primary.withValues(alpha: 0.36),
                      palette.primaryStrong.withValues(alpha: 0.20),
                      const Color(0xFF7B61FF).withValues(alpha: 0.20),
                    ]
                  : [
                      palette.primary,
                      palette.primaryStrong,
                      const Color(0xFF6C7BFF),
                    ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: palette.primary
                    .withValues(alpha: palette.isDark ? 0.20 : 0.30),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative orbs
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -20,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _GlassStatusBadge(status: booking.status),
                      const Spacer(),
                      Text(
                        'ACTIVE TRIP',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _AvatarBubble(name: booking.travelerName),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.travelerName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  Money.egp(booking.payout, decimals: false),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${booking.durationInMinutes}m',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _RouteSummary(
                    pickup: booking.pickupLocation,
                    destination: booking.destinationLocation,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        flex: canChat ? 3 : 1,
                        child: _PrimaryAction(
                          icon: Icons.navigation_rounded,
                          label: 'Open Trip',
                          onTap: () => context.push(
                            AppRouter.helperActiveBooking,
                            extra: booking.id,
                          ),
                        ),
                      ),
                      if (canChat) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _SecondaryAction(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: '',
                            onTap: () => context.push(
                              AppRouter.helperActiveBooking,
                              extra: booking.id,
                            ),
                          ),
                        ),
                      ],
                    ],
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

// ──────────────────────────────────────────────────────────────────────────────
//  GLASS STATUS BADGE
// ──────────────────────────────────────────────────────────────────────────────

class _GlassStatusBadge extends StatelessWidget {
  final String status;
  const _GlassStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  AVATAR BUBBLE
// ──────────────────────────────────────────────────────────────────────────────

class _AvatarBubble extends StatelessWidget {
  final String name;
  const _AvatarBubble({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFF1E40AF),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  ROUTE SUMMARY
// ──────────────────────────────────────────────────────────────────────────────

class _RouteSummary extends StatelessWidget {
  final String pickup;
  final String destination;

  const _RouteSummary({required this.pickup, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: const Color(0xFFFF6B9D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PICKUP',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pickup,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DESTINATION',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destination,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  ACTION BUTTONS
// ──────────────────────────────────────────────────────────────────────────────

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: palette.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: palette.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 17),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
