import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:toury/core/services/haptic_service.dart';
import 'package:toury/features/helper/features/helper_bookings/domain/entities/helper_booking_entities.dart';

import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';


class RequestCard extends StatelessWidget {
  final HelperBooking request;

  const RequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrgent = request.isUrgent;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push(AppRouter.helperRequestDetails.replaceFirst(':id', request.id));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: BrandTokens.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          border: isUrgent 
              ? Border.all(color: BrandTokens.dangerRed.withValues(alpha: 0.3), width: 1.5)
              : Border.all(color: BrandTokens.borderSoft, width: 1),
          boxShadow: BrandTokens.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Urgent highlight background
              if (isUrgent)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(
                      color: BrandTokens.dangerRed,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'URGENT',
                          style: BrandTokens.heading(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Traveler Info Row
                    Row(
                      children: [
                        _buildTravelerImage(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.travelerName,
                                style: BrandTypography.title(),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.public_rounded,
                                    size: 12,
                                    color: BrandTokens.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    request.travelerCountry ?? 'Unknown Country',
                                    style: BrandTypography.caption(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildTypeBadge(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: BrandTokens.borderSoft),
                    const SizedBox(height: 16),

                    // Destination and Logistics
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLogisticsIcon(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                Icons.location_on_outlined,
                                'To ${request.destinationCity}',
                                isBold: true,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.calendar_today_outlined,
                                DateFormat('EEE, MMM d').format(request.startTime),
                              ),
                              const SizedBox(height: 4),
                              _buildInfoRow(
                                Icons.access_time_rounded,
                                '${DateFormat('hh:mm a').format(request.startTime)} (${request.durationInMinutes} min)',
                              ),
                            ],
                          ),
                        ),
                        // Payout
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Payout',
                              style: BrandTypography.caption(color: BrandTokens.textMuted),
                            ),
                            Text(
                              '\$${request.payout.toStringAsFixed(2)}',
                              style: BrandTokens.numeric(
                                fontSize: 20,
                                color: BrandTokens.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (request.notes != null && request.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BrandTokens.bgSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sticky_note_2_outlined, size: 14, color: BrandTokens.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                request.notes!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BrandTypography.caption(color: BrandTokens.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTravelerImage() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BrandTokens.bgSoft,
        border: Border.all(color: BrandTokens.borderSoft, width: 2),
      ),
      child: ClipOval(
        child: request.travelerImage != null
            ? Image.network(
                request.travelerImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: BrandTokens.textMuted),
              )
            : const Icon(Icons.person_rounded, color: BrandTokens.textMuted),
      ),
    );
  }

  Widget _buildTypeBadge() {
    final isInstant = request.bookingType.toLowerCase() == 'instant';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isInstant 
            ? BrandTokens.accentAmberSoft 
            : BrandTokens.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        request.bookingType.toUpperCase(),
        style: BrandTokens.heading(
          fontSize: 10,
          color: isInstant ? BrandTokens.accentAmberText : BrandTokens.primaryBlue,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLogisticsIcon() {
    return Column(
      children: [
        const Icon(Icons.circle, size: 10, color: BrandTokens.primaryBlue),
        Container(
          width: 2,
          height: 24,
          color: BrandTokens.borderSoft,
        ),
        const Icon(Icons.location_on, size: 14, color: BrandTokens.dangerRed),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: BrandTokens.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: isBold 
                ? BrandTypography.body(weight: FontWeight.w600, color: BrandTokens.textPrimary)
                : BrandTypography.caption(),
          ),
        ),
      ],
    );
  }
}
