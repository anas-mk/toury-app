// Modern payout card with a brand gradient, decorative orbs, and the EGP
// payout amount rendered in the largest, most readable typography on the
// details screen.

import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_dimens.dart';
import '../../../../../../../core/utils/currency_format.dart';
import '../../../domain/entities/helper_booking_entities.dart';
import '../../../domain/entities/helper_booking_status_x.dart';

class PaymentInfoCard extends StatelessWidget {
  final HelperBooking booking;
  const PaymentInfoCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.34),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [palette.primary, palette.primaryStrong],
                ),
              ),
            ),
            Positioned(
              top: -36,
              right: -16,
              child: _Orb(size: 140, alpha: 0.10),
            ),
            Positioned(
              bottom: -50,
              left: -20,
              child: _Orb(size: 130, alpha: 0.08),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: AppSize.iconXl,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          booking.isCompleted
                              ? 'PAYOUT RECEIVED'
                              : 'YOUR PAYOUT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Money.egp(booking.payout),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Auto-transferred after trip ends',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (booking.isCompleted)
                    const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.sm),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: AppSize.iconLg,
                      ),
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

class _Orb extends StatelessWidget {
  final double size;
  final double alpha;
  const _Orb({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }
}
