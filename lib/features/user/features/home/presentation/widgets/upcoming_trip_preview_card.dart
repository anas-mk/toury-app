import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../user_booking/domain/entities/booking_detail_entity.dart';

class UpcomingTripPreviewCard extends StatefulWidget {
  final BookingDetailEntity booking;

  const UpcomingTripPreviewCard({super.key, required this.booking});

  @override
  State<UpcomingTripPreviewCard> createState() =>
      _UpcomingTripPreviewCardState();
}

class _UpcomingTripPreviewCardState extends State<UpcomingTripPreviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat(
      'EEE, MMM d, yyyy',
    ).format(widget.booking.requestedDate);
    final timeString = widget.booking.startTime ?? '00:00';

    final durationHours = widget.booking.durationInMinutes >= 60
        ? '${(widget.booking.durationInMinutes / 60).toStringAsFixed(widget.booking.durationInMinutes % 60 == 0 ? 0 : 1)}h'
        : '${widget.booking.durationInMinutes}m';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: () {
            // Unified booking detail (Instant + Scheduled).
            context.pushNamed(
              'booking-details',
              pathParameters: {'id': widget.booking.id},
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.lightBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: City & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.booking.destinationCity,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Upcoming',
                        style: TextStyle(
                          color: AppColor.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMD),

                // Date & Time Row
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppColor.lightTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: AppTheme.spaceLG),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColor.lightTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeString,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spaceSM),
                  child: Divider(height: 1),
                ),

                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: AppColor.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.booking.pickupLocationName ?? 'Location pending',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMD),

                // Secondary Info Row
                Row(
                  children: [
                    _buildInfoChip(Icons.timer_outlined, durationHours),
                    const SizedBox(width: AppTheme.spaceMD),
                    _buildInfoChip(
                      Icons.group_rounded,
                      '1',
                    ), // Assume 1 for now or pull from entity
                    // Assuming required car condition
                    const SizedBox(width: AppTheme.spaceMD),
                    _buildInfoChip(Icons.directions_car_rounded, 'Car'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.lightSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColor.lightTextSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColor.lightTextSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class UpcomingTripEmptyState extends StatelessWidget {
  const UpcomingTripEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppColor.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColor.lightBorder,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_rounded,
            size: 40,
            color: AppColor.lightBorder,
          ),
          const SizedBox(height: AppTheme.spaceMD),
          const Text(
            'No upcoming trips',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColor.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          OutlinedButton(
            onPressed: () => context.push(AppRouter.scheduledSearch),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.primaryColor,
              side: const BorderSide(color: AppColor.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Explore Tours'),
          ),
        ],
      ),
    );
  }
}

class UpcomingTripSkeleton extends StatelessWidget {
  const UpcomingTripSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerBox(width: 120, height: 24),
              _buildShimmerBox(width: 80, height: 24, radius: 12),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              _buildShimmerBox(width: 100, height: 16),
              const SizedBox(width: AppTheme.spaceLG),
              _buildShimmerBox(width: 80, height: 16),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.spaceSM),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              _buildShimmerBox(width: 20, height: 20, radius: 10),
              const SizedBox(width: 8),
              _buildShimmerBox(width: 200, height: 16),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              _buildShimmerBox(width: 60, height: 24, radius: 8),
              const SizedBox(width: AppTheme.spaceMD),
              _buildShimmerBox(width: 50, height: 24, radius: 8),
              const SizedBox(width: AppTheme.spaceMD),
              _buildShimmerBox(width: 60, height: 24, radius: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double radius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColor.lightBorder.withOpacity(0.3),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
