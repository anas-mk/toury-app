import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/brand/brand_kit.dart';
import '../../../domain/entities/helper_booking_entity.dart';
import '../../../domain/entities/search_params.dart';
import '../../cubits/booking_cubit.dart';
import '../../cubits/booking_state.dart';
import '../../widgets/scheduled/scheduled_trip_config.dart';

/// Phase 4 — last screen before the user creates the booking.
///
/// Reuses [BookingCubit.createScheduled] (which now also accepts
/// `meetingPointType`) per the Reuse > Create guardrail. On success
/// pushes the booking detail screen — payment is initiated from there.
class ScheduledReviewScreen extends StatelessWidget {
  final HelperBookingEntity helper;
  final ScheduledSearchParams params;
  final ScheduledTripConfig config;

  const ScheduledReviewScreen({
    super.key,
    required this.helper,
    required this.params,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingCubit>(
      create: (_) => sl<BookingCubit>(),
      child: BlocListener<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingCreated) {
            HapticFeedback.lightImpact();
            // Single source of truth: detail screen owns the booking
            // state and will fetch the full BookingDetail via REST
            // before showing payment options. We replace this screen
            // so the back stack lands on the helpers list.
            context.pushReplacement(
              AppRouter.bookingDetails
                  .replaceFirst(':id', state.booking.id),
            );
          } else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: BrandTokens.dangerRed,
              ),
            );
          }
        },
        child: _ReviewView(
          helper: helper,
          params: params,
          config: config,
        ),
      ),
    );
  }
}

class _ReviewView extends StatelessWidget {
  final HelperBookingEntity helper;
  final ScheduledSearchParams params;
  final ScheduledTripConfig config;

  const _ReviewView({
    required this.helper,
    required this.params,
    required this.config,
  });

  void _confirm(BuildContext context) {
    HapticFeedback.lightImpact();

    // Defense in depth (Fix 4): block the create call if the user fiddled
    // with their device clock or sat on this screen long enough for the
    // start time to slip into the past.
    if (_startInPast) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Trip start is in the past. Please go back and pick a future time.',
          ),
          backgroundColor: BrandTokens.dangerRed,
        ),
      );
      return;
    }

    context.read<BookingCubit>().createScheduled(
          helperId: helper.id,
          params: params,
          // Pickup stays optional (Fix 3): null fields are dropped from
          // the JSON payload so the backend never sees zero coords.
          pickupLocationName: config.pickupLocationName,
          pickupLatitude: config.pickupLatitude,
          pickupLongitude: config.pickupLongitude,
          // Destination is REQUIRED — coords already validated in the
          // sheet (Fix 1) so we send them as-is.
          destinationName: config.destinationName,
          destinationLatitude: config.destinationLatitude,
          destinationLongitude: config.destinationLongitude,
          distanceKm: config.distanceKm,
          notes: config.notes,
          // Pascal-case wire ("Custom" | "Hotel" | "Airport") — Fix 5.
          meetingPointType: config.meetingPointType.wire,
        );
  }

  /// Re-runs the past-time check on the composed start moment. Used by
  /// `_confirm` and the price-card disclaimer.
  bool get _startInPast {
    final base = params.requestedDate.toLocal();
    final parts = params.startTime.split(':');
    if (parts.length < 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return false;
    final composed = DateTime(base.year, base.month, base.day, h, m);
    return composed.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final hours = params.durationInMinutes ~/ 60;
    final hourlyRate = helper.hourlyRate ?? 0;
    final estimatedTotal =
        helper.estimatedPrice ?? (hourlyRate * hours).toDouble();

    return PageScaffold(
      bottomCta: BlocBuilder<BookingCubit, BookingState>(
        builder: (context, state) {
          final loading = state is BookingLoading;
          return PrimaryGradientButton(
            label: 'Confirm and request',
            icon: Icons.send_rounded,
            isLoading: loading,
            onPressed: loading ? null : () => _confirm(context),
          );
        },
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: BrandTokens.bgSoft,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: BrandTokens.textPrimary),
            title: Text(
              'Review your trip',
              style: BrandTypography.title(weight: FontWeight.w700),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverList.list(
              children: [
                _HelperRow(helper: helper),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Trip',
                  children: [
                    _Row(
                      icon: Icons.flag_rounded,
                      label: 'Destination',
                      value: config.destinationName,
                    ),
                    _Row(
                      icon: Icons.place_rounded,
                      label: 'Meeting point',
                      value: config.meetingPointType.label,
                    ),
                    if (config.pickupLocationName != null &&
                        config.pickupLocationName!.isNotEmpty)
                      _Row(
                        icon: Icons.my_location_rounded,
                        label: 'Pickup',
                        value: config.pickupLocationName!,
                      ),
                    _Row(
                      icon: Icons.event_rounded,
                      label: 'Date',
                      value: _fmtDate(params.requestedDate),
                    ),
                    _Row(
                      icon: Icons.schedule_rounded,
                      label: 'Start',
                      value: params.startTime.substring(0, 5),
                    ),
                    _Row(
                      icon: Icons.hourglass_top_rounded,
                      label: 'Duration',
                      value: _fmtDuration(params.durationInMinutes),
                    ),
                    _Row(
                      icon: Icons.translate_rounded,
                      label: 'Language',
                      value: params.requestedLanguage.toUpperCase(),
                    ),
                    if (params.requiresCar)
                      const _Row(
                        icon: Icons.directions_car_rounded,
                        label: 'Car',
                        value: 'Required',
                      ),
                    _Row(
                      icon: Icons.group_rounded,
                      label: 'Travelers',
                      value: params.travelersCount.toString(),
                    ),
                  ],
                ),
                if (config.notes != null && config.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Notes',
                    children: [
                      Text(
                        config.notes!,
                        style: BrandTypography.body(
                          color: BrandTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _PriceCard(
                  hourlyRate: hourlyRate.toDouble(),
                  hours: hours.toDouble(),
                  estimatedTotal: estimatedTotal.toDouble(),
                ),
                const SizedBox(height: 16),
                _Disclaimer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String _fmtDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h hour${h == 1 ? '' : 's'}';
    return '${h}h ${m}m';
  }
}

class _HelperRow extends StatelessWidget {
  final HelperBookingEntity helper;
  const _HelperRow({required this.helper});

  @override
  Widget build(BuildContext context) {
    final initial =
        helper.name.isEmpty ? '?' : helper.name.substring(0, 1).toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Row(
        children: [
          ClipOval(
            child: helper.profileImageUrl == null ||
                    helper.profileImageUrl!.isEmpty
                ? Container(
                    width: 56,
                    height: 56,
                    color: BrandTokens.borderTinted,
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: BrandTypography.title(
                        weight: FontWeight.w700,
                        color: BrandTokens.primaryBlue,
                      ),
                    ),
                  )
                : Image.network(
                    helper.profileImageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: BrandTokens.borderTinted,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_rounded,
                        color: BrandTokens.primaryBlue,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  helper.name,
                  style: BrandTypography.title(weight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFB45309),
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      helper.rating.toStringAsFixed(1),
                      style: BrandTypography.caption(
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${helper.completedTrips} trips',
                      style: BrandTypography.caption(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: BrandTypography.body(weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: BrandTokens.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: BrandTypography.caption()),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: BrandTypography.body(weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final double hourlyRate;
  final double hours;
  final double estimatedTotal;

  const _PriceCard({
    required this.hourlyRate,
    required this.hours,
    required this.estimatedTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFAEB), Color(0xFFFDF6E3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandTokens.accentAmberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.payments_rounded,
                color: Color(0xFFB45309),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Estimated price',
                style: BrandTypography.body(
                  weight: FontWeight.w700,
                  color: BrandTokens.accentAmberText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${hourlyRate.toStringAsFixed(0)} EGP / hr',
                style: BrandTypography.caption(
                  color: BrandTokens.accentAmberText,
                ),
              ),
              const Spacer(),
              Text(
                '${hours.toStringAsFixed(0)} hr${hours == 1 ? '' : 's'}',
                style: BrandTypography.caption(
                  color: BrandTokens.accentAmberText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: BrandTokens.accentAmberBorder,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Estimated total',
                style:
                    BrandTypography.title(weight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${estimatedTotal.toStringAsFixed(0)} EGP',
                style: BrandTypography.headline(
                  color: BrandTokens.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Final price is calculated by the helper after the trip ends '
            '(distance + time).',
            style: BrandTypography.caption(
              color: BrandTokens.accentAmberText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandTokens.bgSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: BrandTokens.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You won\u2019t be charged until the helper accepts. You can '
              'cancel without penalty before the trip starts.',
              style: BrandTypography.caption(
                color: BrandTokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
