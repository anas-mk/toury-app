import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toury/core/widgets/custom_card.dart';
import 'package:toury/features/helper/features/helper_bookings/domain/entities/helper_booking_entities.dart';

import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';


class BookingRouteCard extends StatelessWidget {
  final HelperBooking booking;
  const BookingRouteCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TRIP LOGISTICS', style: BrandTypography.caption(weight: FontWeight.bold, color: BrandTokens.textMuted)),
          const SizedBox(height: 20),
          _buildLocationItem(
            icon: Icons.circle_outlined,
            color: BrandTokens.successGreen,
            title: 'Pickup Location',
            value: booking.pickupLocation,
          ),
          _buildConnector(),
          _buildLocationItem(
            icon: Icons.location_on_rounded,
            color: BrandTokens.dangerRed,
            title: 'Destination',
            value: booking.destinationLocation,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: BrandTokens.borderSoft),
          ),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.calendar_today_rounded,
                  'Date',
                  DateFormat('EEE, MMM d, yyyy').format(booking.startTime),
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.access_time_rounded,
                  'Time',
                  DateFormat('hh:mm a').format(booking.startTime),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.timer_outlined,
                  'Duration',
                  '${booking.durationInMinutes} Minutes',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.people_outline_rounded,
                  'Travelers',
                  '${booking.travelersCount} People',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem({required IconData icon, required Color color, required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: BrandTypography.caption(color: BrandTokens.textMuted)),
              Text(value, style: BrandTypography.body(weight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 7.5),
      child: Container(
        width: 1,
        height: 20,
        color: BrandTokens.borderSoft,
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: BrandTokens.primaryBlue),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: BrandTokens.body(fontSize: 10, color: BrandTokens.textMuted)),
            Text(value, style: BrandTokens.body(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
