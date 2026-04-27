import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../../core/widgets/hero_header.dart';
import '../../../domain/entities/create_instant_booking_request.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import '../../widgets/instant/duration_picker_sheet.dart';
import '../../widgets/instant/language_picker_sheet.dart';
import '../../widgets/instant/price_breakdown_card.dart';
import 'location_pick_result.dart';

/// Step 6 â€” read-only review of the trip + helper before firing
/// `POST /user/bookings/instant`. On success we replace the stack with
/// the WaitingForHelperPage so back doesn't return here.
class BookingReviewPage extends StatelessWidget {
  final InstantBookingCubit cubit;
  final HelperSearchResult helper;
  final LocationPickResult pickup;
  final LocationPickResult destination;
  final int travelers;
  final int durationInMinutes;
  final String? languageCode;
  final bool requiresCar;
  final String? notes;

  const BookingReviewPage({
    super.key,
    required this.cubit,
    required this.helper,
    required this.pickup,
    required this.destination,
    required this.travelers,
    required this.durationInMinutes,
    required this.languageCode,
    required this.requiresCar,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: _ReviewView(
        helper: helper,
        pickup: pickup,
        destination: destination,
        travelers: travelers,
        durationInMinutes: durationInMinutes,
        languageCode: languageCode,
        requiresCar: requiresCar,
        notes: notes,
      ),
    );
  }
}

class _ReviewView extends StatelessWidget {
  final HelperSearchResult helper;
  final LocationPickResult pickup;
  final LocationPickResult destination;
  final int travelers;
  final int durationInMinutes;
  final String? languageCode;
  final bool requiresCar;
  final String? notes;

  const _ReviewView({
    required this.helper,
    required this.pickup,
    required this.destination,
    required this.travelers,
    required this.durationInMinutes,
    required this.languageCode,
    required this.requiresCar,
    required this.notes,
  });

  void _confirm(BuildContext context) {
    final request = CreateInstantBookingRequest(
      helperId: helper.helperId,
      pickupLocationName: pickup.name,
      pickupLatitude: pickup.latitude,
      pickupLongitude: pickup.longitude,
      destinationName: destination.name,
      destinationLatitude: destination.latitude,
      destinationLongitude: destination.longitude,
      durationInMinutes: durationInMinutes,
      requestedLanguage: languageCode,
      requiresCar: requiresCar,
      travelersCount: travelers,
      notes: notes,
    );
    context.read<InstantBookingCubit>().createBooking(request);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final breakdown = helper.priceBreakdown;
    final language = languageOptionForCode(languageCode);

    return BlocConsumer<InstantBookingCubit, InstantBookingState>(
      listener: (context, state) {
        if (state is InstantBookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColor.errorColor,
            ),
          );
        }
        if (state is InstantBookingCreated || state is InstantBookingWaiting) {
          final booking = state is InstantBookingCreated
              ? state.booking
              : (state as InstantBookingWaiting).booking;
          context.pushReplacement(
            AppRouter.instantWaiting.replaceFirst(':id', booking.bookingId),
            extra: {
              'cubit': context.read<InstantBookingCubit>(),
              'helper': helper,
            },
          );
        }
      },
      builder: (context, state) {
        final loading = state is InstantBookingCreating;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          extendBodyBehindAppBar: true,
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLG,
                AppTheme.spaceMD,
                AppTheme.spaceLG,
                AppTheme.spaceLG,
              ),
              child: _GradientCta(
                label: loading ? 'Sending requestâ€¦' : 'Confirm & send request',
                icon: Icons.send_rounded,
                isLoading: loading,
                onTap: loading ? null : () => _confirm(context),
              ),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: false,
                delegate: HeroSliverHeader(
                  title: 'Review your booking',
                  subtitle: 'Make sure everything looks right',
                  leadingIcon: Icons.fact_check_rounded,
                  height: 200,
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HelperMiniCard(helper: helper),
                        const SizedBox(height: AppTheme.spaceLG),
                        SectionTitle('Itinerary'),
                        const SizedBox(height: AppTheme.spaceSM),
                        _ItineraryCard(
                          pickup: pickup,
                          destination: destination,
                          durationLabel:
                              formatDurationMinutes(durationInMinutes),
                        ),
                        const SizedBox(height: AppTheme.spaceLG),
                        SectionTitle('Trip details'),
                        const SizedBox(height: AppTheme.spaceSM),
                        _DetailsCard(
                          rows: [
                            _DetailRow(
                              icon: Icons.schedule_rounded,
                              label: 'Duration',
                              value: formatDurationMinutes(durationInMinutes),
                              color: AppColor.secondaryColor,
                            ),
                            _DetailRow(
                              icon: Icons.group_rounded,
                              label: 'Travelers',
                              value: '$travelers',
                              color: AppColor.accentColor,
                            ),
                            _DetailRow(
                              icon: Icons.translate_rounded,
                              label: 'Preferred language',
                              value: language.name,
                              color: AppColor.secondaryColor,
                            ),
                            _DetailRow(
                              icon: Icons.directions_car_rounded,
                              label: 'Car required',
                              value: requiresCar ? 'Yes' : 'No',
                              color: AppColor.warningColor,
                            ),
                          ],
                        ),
                        if ((notes ?? '').isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spaceLG),
                          SectionTitle('Notes'),
                          const SizedBox(height: AppTheme.spaceSM),
                          _SoftCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.note_alt_rounded,
                                  color: AppColor.lightTextSecondary,
                                ),
                                const SizedBox(width: AppTheme.spaceSM),
                                Expanded(
                                  child: Text(
                                    notes!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppTheme.spaceLG),
                        SectionTitle('Price breakdown'),
                        const SizedBox(height: AppTheme.spaceSM),
                        if (breakdown != null)
                          PriceBreakdownCard(breakdown: breakdown)
                        else
                          _SoftCard(
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColor.accentColor
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.payments_rounded,
                                    color: AppColor.accentColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceMD),
                                Expanded(
                                  child: Text(
                                    'Estimated total',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                Text(
                                  'EGP ${helper.estimatedPrice.toStringAsFixed(0)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HelperMiniCard extends StatelessWidget {
  final HelperSearchResult helper;
  const _HelperMiniCard({required this.helper});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              AppNetworkImage(
                imageUrl: helper.profileImageUrl,
                width: 56,
                height: 56,
                borderRadius: 28,
              ),
              const Positioned(
                right: -2,
                bottom: -2,
                child: Icon(
                  Icons.verified_rounded,
                  color: AppColor.accentColor,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  helper.fullName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF5A623),
                      size: 16,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      helper.rating.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      '${helper.completedTrips} trips',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColor.lightTextSecondary,
                      ),
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

class _ItineraryCard extends StatelessWidget {
  final LocationPickResult pickup;
  final LocationPickResult destination;
  final String durationLabel;
  const _ItineraryCard({
    required this.pickup,
    required this.destination,
    required this.durationLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _Endpoint(
            color: AppColor.accentColor,
            label: 'PICKUP',
            name: pickup.name,
            address: pickup.address,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Container(
                  width: 2,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColor.lightBorder,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.lightBorder,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: AppColor.lightTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        durationLabel,
                        style: const TextStyle(
                          color: AppColor.lightTextSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _Endpoint(
            color: AppColor.errorColor,
            label: 'DESTINATION',
            name: destination.name,
            address: destination.address,
          ),
        ],
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  final Color color;
  final String label;
  final String name;
  final String? address;
  const _Endpoint({
    required this.color,
    required this.label,
    required this.name,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  color: AppColor.lightTextSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((address ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    address!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColor.lightTextSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _DetailsCard extends StatelessWidget {
  final List<_DetailRow> rows;
  const _DetailsCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: rows[i].color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: Icon(
                      rows[i].icon,
                      color: rows[i].color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColor.lightTextSecondary,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMD,
                ),
                height: 1,
                color: AppColor.lightBorder,
              ),
          ],
        ],
      ),
    );
  }
}

class _GradientCta extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;
  const _GradientCta({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_GradientCta> createState() => _GradientCtaState();
}

class _GradientCtaState extends State<_GradientCta> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    return AnimatedScale(
      duration: const Duration(milliseconds: 90),
      scale: _down ? 0.98 : 1,
      child: Opacity(
        opacity: enabled ? 1 : 0.7,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              gradient: const LinearGradient(
                colors: [AppColor.accentColor, AppColor.secondaryColor],
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColor.accentColor.withValues(alpha: 0.32),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                onTap: enabled ? widget.onTap : null,
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(widget.icon, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              widget.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
