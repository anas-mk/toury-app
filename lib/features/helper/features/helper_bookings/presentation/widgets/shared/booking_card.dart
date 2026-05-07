import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/helper/features/helper_bookings/domain/entities/helper_booking_entities.dart';
import 'package:toury/core/config/api_config.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/custom_card.dart';
import '../../../../../../../core/widgets/booking_status_chip.dart';
import '../../../../../../../core/services/haptic_service.dart';
import '../../../../../../user/features/user_booking/domain/entities/booking_detail_entity.dart';

class BookingCard extends StatelessWidget {
  final HelperBooking booking;
  const BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusLower = booking.status.toLowerCase();
    final isHistory = statusLower == 'completed' || statusLower == 'cancelled'
        || statusLower == 'cancelledbyhelper' || statusLower == 'cancelledbytraveler'
        || statusLower == 'cancelledbyadmin';
    
    return GestureDetector(
      onTap: () {
        HapticService.light();
        final isPending = statusLower == 'pending' || statusLower == 'pendinghelperresponse';
        final route = isPending
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
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: booking.isInstant
                              ? BrandTokens.warningAmber.withValues(alpha: 0.16)
                              : BrandTokens.primaryBlue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          booking.isInstant ? 'Instant' : 'Scheduled',
                          style: BrandTypography.caption(
                            weight: FontWeight.w600,
                            color: booking.isInstant
                                ? BrandTokens.warningAmber
                                : BrandTokens.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
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
                if (!isHistory) _buildPrimaryHint(statusLower),
              ],
            ),
            if (!isHistory) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: BrandTokens.primaryBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _nextActionText(statusLower),
                  style: BrandTypography.caption(
                    color: BrandTokens.primaryBlue,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryHint(String statusLower) {
    IconData icon = Icons.arrow_forward_ios_rounded;
    if (_isPending(statusLower)) {
      icon = Icons.notification_important_rounded;
    } else if (_isActive(statusLower)) {
      icon = Icons.gps_fixed_rounded;
    } else if (_isConfirmed(statusLower)) {
      icon = Icons.play_circle_fill_rounded;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: BrandTokens.bgSoft,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: BrandTokens.primaryBlue, size: 16),
    );
  }

  bool _isPending(String s) => s == 'pending' || s == 'pendinghelperresponse';
  bool _isConfirmed(String s) =>
      s == 'confirmed' ||
      s == 'accepted' ||
      s == 'acceptedbyhelper' ||
      s == 'confirmedpaid';
  bool _isActive(String s) => s == 'inprogress' || s == 'started' || s == 'active';

  String _nextActionText(String statusLower) {
    if (_isPending(statusLower)) return 'Next: review request (accept or decline).';
    if (_isConfirmed(statusLower)) return 'Next: open details and start trip when ready.';
    if (_isActive(statusLower)) return 'Next: open live tracking to continue the trip.';
    return 'Open details for more information.';
  }

  Widget _buildAvatar() {
    final imageUrl = booking.travelerImage;
    final resolvedImageUrl = ApiConfig.resolveImageUrl(imageUrl);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BrandTokens.primaryBlue.withValues(alpha: 0.1),
        border: Border.all(color: BrandTokens.primaryBlue.withValues(alpha: 0.2), width: 1),
      ),
      child: ClipOval(
        child: resolvedImageUrl.isNotEmpty
            ? Image.network(
                resolvedImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialAvatar(),
              )
            : _initialAvatar(),
      ),
    );
  }

  Widget _initialAvatar() {
    return Center(
      child: Text(
        booking.travelerName.isNotEmpty ? booking.travelerName[0].toUpperCase() : '?',
        style: BrandTokens.body(
          color: BrandTokens.primaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    return '${date.day}/${date.month}/${date.year} $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  BookingStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      // Pending
      case 'pending':
      case 'pendinghelperresponse':
        return BookingStatus.pendingHelperResponse;
      // Accepted / confirmed
      case 'accepted':
      case 'acceptedbyhelper':
        return BookingStatus.acceptedByHelper;
      case 'confirmed':
      case 'confirmedpaid':
        return BookingStatus.confirmedPaid;
      // Active
      case 'inprogress':
      case 'started':
      case 'active':
        return BookingStatus.inProgress;
      // Completed
      case 'completed':
        return BookingStatus.completed;
      // Cancelled variants
      case 'cancelled':
      case 'cancelledbyhelper':
        return BookingStatus.cancelledByHelper;
      case 'cancelledbytraveler':
        return BookingStatus.cancelledByTraveler;
      default:
        return BookingStatus.pendingHelperResponse;
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
