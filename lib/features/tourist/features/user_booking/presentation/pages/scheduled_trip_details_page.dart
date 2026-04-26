import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';

class ScheduledTripEntity {
  final String helperId;
  final String destinationCity;
  final DateTime requestedDate;
  final String startTime;
  final int durationInMinutes;
  final String requestedLanguage;
  final bool requiresCar;
  final int travelersCount;
  final String meetingPointType;
  final String pickupLocationName;
  final double pickupLatitude;
  final double pickupLongitude;
  final String? notes;

  const ScheduledTripEntity({
    required this.helperId,
    required this.destinationCity,
    required this.requestedDate,
    required this.startTime,
    required this.durationInMinutes,
    required this.requestedLanguage,
    required this.requiresCar,
    required this.travelersCount,
    required this.meetingPointType,
    required this.pickupLocationName,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.notes,
  });
}

class ScheduledTripDetailsPage extends StatelessWidget {
  final ScheduledTripEntity? trip;
  final bool isLoading;

  const ScheduledTripDetailsPage({
    super.key,
    this.trip,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(context),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const _TripDetailsSkeleton();
    }

    if (trip == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TripOverviewCard(trip: trip!),
          const SizedBox(height: AppTheme.spaceLG),
          _ScheduleInfoCard(trip: trip!),
          const SizedBox(height: AppTheme.spaceLG),
          _PickupDetailsCard(trip: trip!),
          const SizedBox(height: AppTheme.spaceLG),
          _TravelersInfoCard(trip: trip!),
          if (trip!.notes != null && trip!.notes!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceLG),
            _NotesCard(notes: trip!.notes!),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 80, color: AppColor.lightBorder),
          const SizedBox(height: AppTheme.spaceMD),
          const Text(
            'Trip Details Unavailable',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          const Text(
            'We couldn\'t load the details for this scheduled trip.',
            style: TextStyle(color: AppColor.lightTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(BuildContext context) {
    if (isLoading || trip == null) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Modify Trip',
                variant: ButtonVariant.secondary,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: CustomButton(
                text: 'Contact Guide',
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppColor.lightBorder.withOpacity(0.5)),
        boxShadow: AppTheme.shadowLight(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.spaceLG, AppTheme.spaceLG, AppTheme.spaceLG, AppTheme.spaceMD),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColor.primaryColor),
                const SizedBox(width: AppTheme.spaceSM),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColor.lightTextSecondary),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColor.lightTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripOverviewCard extends StatelessWidget {
  final ScheduledTripEntity trip;

  const _TripOverviewCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppColor.primaryColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowMedium(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESTINATION',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trip.destinationCity,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Row(
            children: [
              _buildBadge(
                Icons.language_rounded,
                trip.requestedLanguage.toUpperCase(),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              _buildBadge(
                trip.requiresCar ? Icons.directions_car_rounded : Icons.directions_walk_rounded,
                trip.requiresCar ? 'Car Included' : 'Walking Tour',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleInfoCard extends StatelessWidget {
  final ScheduledTripEntity trip;

  const _ScheduleInfoCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(trip.requestedDate);
    final formattedDuration = trip.durationInMinutes >= 60
        ? '${(trip.durationInMinutes / 60).toStringAsFixed(trip.durationInMinutes % 60 == 0 ? 0 : 1)} hours'
        : '${trip.durationInMinutes} minutes';

    return _SectionCard(
      title: 'Schedule Info',
      icon: Icons.calendar_today_rounded,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.event_rounded,
            label: 'Date',
            value: formattedDate,
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.access_time_rounded,
                  label: 'Start Time',
                  value: trip.startTime,
                ),
              ),
              Expanded(
                child: _InfoRow(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: formattedDuration,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickupDetailsCard extends StatelessWidget {
  final ScheduledTripEntity trip;

  const _PickupDetailsCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Pickup Details',
      icon: Icons.location_on_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Icons.meeting_room_rounded,
            label: 'Meeting Point Type',
            value: trip.meetingPointType,
          ),
          const SizedBox(height: AppTheme.spaceLG),
          _InfoRow(
            icon: Icons.place_rounded,
            label: 'Location Name',
            value: trip.pickupLocationName,
          ),
          const SizedBox(height: AppTheme.spaceLG),
          _MapPreviewWidget(
            latitude: trip.pickupLatitude,
            longitude: trip.pickupLongitude,
          ),
        ],
      ),
    );
  }
}

class _MapPreviewWidget extends StatelessWidget {
  final double latitude;
  final double longitude;

  const _MapPreviewWidget({
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppColor.lightBorder),
      ),
      child: Stack(
        children: [
          // In a real app, use GoogleMaps or flutter_map here
          Center(
            child: Icon(Icons.map_rounded, size: 48, color: AppColor.lightBorder),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: FilledButton.icon(
              onPressed: () {}, // Open maps logic
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: const Text('Open in Maps'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 32),
                backgroundColor: Colors.white,
                foregroundColor: AppColor.primaryColor,
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelersInfoCard extends StatelessWidget {
  final ScheduledTripEntity trip;

  const _TravelersInfoCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Travelers Info',
      icon: Icons.group_rounded,
      child: _InfoRow(
        icon: Icons.person_rounded,
        label: 'Number of Travelers',
        value: '${trip.travelersCount} ${trip.travelersCount == 1 ? 'Person' : 'People'}',
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;

  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppColor.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppColor.warningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 20, color: AppColor.warningColor.withOpacity(0.8)),
              const SizedBox(width: AppTheme.spaceSM),
              Text(
                'Additional Notes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColor.warningColor.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            notes,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColor.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripDetailsSkeleton extends StatelessWidget {
  const _TripDetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        children: [
          _buildSkeletonBox(height: 160),
          const SizedBox(height: AppTheme.spaceLG),
          _buildSkeletonBox(height: 140),
          const SizedBox(height: AppTheme.spaceLG),
          _buildSkeletonBox(height: 250),
          const SizedBox(height: AppTheme.spaceLG),
          _buildSkeletonBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.lightBorder.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
    );
  }
}
