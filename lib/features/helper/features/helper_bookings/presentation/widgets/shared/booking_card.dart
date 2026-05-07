import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/helper/features/helper_bookings/domain/entities/helper_booking_entities.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/custom_card.dart';
import '../../../../../../../core/widgets/booking_status_chip.dart';
import '../../../../../../../core/services/haptic_service.dart';
import '../../../../../../tourist/features/user_booking/domain/entities/booking_detail_entity.dart';

class BookingCard extends StatelessWidget {
  final HelperBooking booking;
  const BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final isHistory = booking.status == 'completed' || booking.status == 'cancelled';
    
    return GestureDetector(
      onTap: () {
        HapticService.light();
        final route = booking.status.toLowerCase() == 'pending' 
            ? AppRouter.helperRequestDetails 
            : AppRouter.helperBookingDetails;
        context.push(route.replaceFirst(':id', booking.id));
      },
      child: CustomCard(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.travelerName,
                        style: BrandTypography.body(weight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(booking.startTime),
                        style: BrandTypography.caption(color: BrandTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
                BookingStatusChip(status: _mapStatus(booking.status)),
              ],
            ),
            const SizedBox(height: 20),
            _LocationRow(
              icon: Icons.circle_outlined, 
              color: BrandTokens.successGreen, 
              label: booking.pickupLocation,
              isFirst: true,
            ),
            _LocationRow(
              icon: Icons.location_on_rounded, 
              color: BrandTokens.dangerRed, 
              label: booking.destinationLocation,
              isLast: true,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expected Payout',
                      style: BrandTypography.caption(color: BrandTokens.textMuted),
                    ),
                    Text(
                      '\$${booking.payout.toStringAsFixed(2)}',
                      style: BrandTokens.numeric(
                        fontSize: 22,
                        color: BrandTokens.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!isHistory)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BrandTokens.bgSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded, 
                      color: BrandTokens.primaryBlue, 
                      size: 14
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BrandTokens.primaryBlue.withValues(alpha: 0.1),
        border: Border.all(color: BrandTokens.primaryBlue.withValues(alpha: 0.2), width: 1),
      ),
      child: Center(
        child: Text(
          booking.travelerName.isNotEmpty ? booking.travelerName[0].toUpperCase() : '?',
          style: BrandTokens.body(
            color: BrandTokens.primaryBlue, 
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  BookingStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return BookingStatus.pendingHelperResponse;
      case 'accepted': return BookingStatus.acceptedByHelper;
      case 'confirmed': return BookingStatus.confirmedPaid;
      case 'inprogress': return BookingStatus.inProgress;
      case 'completed': return BookingStatus.completed;
      case 'cancelled': return BookingStatus.cancelledByHelper;
      default: return BookingStatus.pendingHelperResponse;
    }
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isFirst;
  final bool isLast;

  const _LocationRow({
    required this.icon, 
    required this.color, 
    required this.label,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Icon(icon, color: color, size: 14),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: BrandTokens.borderSoft,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BrandTypography.caption(
                  color: isFirst || isLast ? BrandTokens.textPrimary : BrandTokens.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
