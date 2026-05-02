import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../domain/entities/helper_booking_entities.dart';
import '../../../../../../../core/theme/brand_tokens.dart';

class ActiveTripCard extends StatelessWidget {
  final HelperBooking booking;

  const ActiveTripCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final s = booking.status.toLowerCase();
    final canChat = ['accepted', 'confirmed', 'inProgress', 'started'].contains(s);

    return GestureDetector(
      onTap: () => context.push(AppRouter.helperActiveBooking, extra: booking.id),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [BrandTokens.primaryBlue, BrandTokens.primaryBlueDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: BrandTokens.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.white, size: 8),
                      const SizedBox(width: 6),
                      Text(
                        booking.status.toUpperCase(),
                        style: BrandTypography.overline(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              booking.travelerName,
              style: BrandTypography.headline(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.destinationLocation,
                    style: BrandTypography.caption(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _TripAction(
                    label: 'Navigation',
                    icon: Icons.navigation_rounded,
                    onTap: () => context.push(AppRouter.helperActiveBooking, extra: booking.id),
                  ),
                ),
                if (canChat) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TripAction(
                      label: 'Chat',
                      icon: Icons.chat_bubble_rounded,
                      outline: true,
                      onTap: () => context.push(AppRouter.helperActiveBooking, extra: booking.id),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outline;

  const _TripAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: outline ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: outline ? Border.all(color: Colors.white.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: outline ? Colors.white : BrandTokens.primaryBlue, 
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: BrandTypography.body(
                color: outline ? Colors.white : BrandTokens.primaryBlue,
                weight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
