import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../../../core/localization/app_localizations.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../../core/widgets/brand_widgets.dart';
import '../../../../../../../core/widgets/hero_header.dart';
import '../../../domain/entities/app_payment_method.dart';
import '../../../domain/entities/create_instant_booking_request.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import '../../widgets/instant/duration_picker_sheet.dart';
import '../../widgets/instant/language_picker_sheet.dart';
import '../../widgets/instant/price_breakdown_card.dart';
import 'location_pick_result.dart';

/// Step 6 — read-only review of the trip + helper before firing
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
        cubit: cubit,
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

class _ReviewView extends StatefulWidget {
  final InstantBookingCubit cubit;
  final HelperSearchResult helper;
  final LocationPickResult pickup;
  final LocationPickResult destination;
  final int travelers;
  final int durationInMinutes;
  final String? languageCode;
  final bool requiresCar;
  final String? notes;

  const _ReviewView({
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
  State<_ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<_ReviewView> {
  late AppPaymentMethod _paymentMethod;

  @override
  void initState() {
    super.initState();
    _paymentMethod = widget.cubit.selectedPaymentMethod;
  }

  bool get _canConfirm {
    if (widget.pickup.name.trim().isEmpty ||
        widget.destination.name.trim().isEmpty) {
      return false;
    }
    if (widget.durationInMinutes < kMinDurationMinutes ||
        widget.durationInMinutes > kMaxDurationMinutes) {
      return false;
    }
    if (widget.travelers < 1 || widget.travelers > 20) return false;
    return true;
  }

  void _fireCreate(BuildContext context) {
    final request = CreateInstantBookingRequest(
      helperId: widget.helper.helperId,
      pickupLocationName: widget.pickup.name,
      pickupLatitude: widget.pickup.latitude,
      pickupLongitude: widget.pickup.longitude,
      destinationName: widget.destination.name,
      destinationLatitude: widget.destination.latitude,
      destinationLongitude: widget.destination.longitude,
      durationInMinutes: widget.durationInMinutes,
      requestedLanguage: widget.languageCode,
      requiresCar: widget.requiresCar,
      travelersCount: widget.travelers,
      notes: widget.notes,
    );
    context.read<InstantBookingCubit>().createBooking(request);
  }

  void _onConfirmPressed(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (!_canConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.bookingReviewValidationSnackbar)),
      );
      return;
    }
    _fireCreate(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final breakdown = widget.helper.priceBreakdown;
    final language = languageOptionForCode(widget.languageCode);

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
              'helper': widget.helper,
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
                label: loading
                    ? loc.bookingReviewConfirmLoading
                    : loc.bookingReviewConfirm,
                icon: Icons.send_rounded,
                isLoading: loading,
                visualEnabled: _canConfirm,
                onTap: loading ? null : () => _onConfirmPressed(context),
              ),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: false,
                delegate: HeroSliverHeader(
                  title: loc.bookingReviewTitle,
                  subtitle: loc.bookingReviewSubtitle,
                  leadingIcon: Icons.fact_check_rounded,
                  height: 200,
                  gradient: const [
                    BrandTokens.primaryBlue,
                    BrandTokens.primaryBlueDark,
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceLG,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HelperMiniCard(helper: widget.helper),
                        const SizedBox(height: AppTheme.spaceLG),
                        BrandSectionTitle(loc.bookingReviewPaymentTitle),
                        const SizedBox(height: AppTheme.spaceSM),
                        BrandCard(
                          child: SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<AppPaymentMethod>(
                              segments: [
                                ButtonSegment(
                                  value: AppPaymentMethod.cash,
                                  label: Text(loc.bookingReviewPayCash),
                                  icon: const Icon(Icons.payments_outlined, size: 18),
                                ),
                                ButtonSegment(
                                  value: AppPaymentMethod.mockCard,
                                  label: Text(loc.bookingReviewPayCard),
                                  icon: const Icon(Icons.credit_card, size: 18),
                                ),
                              ],
                              selected: {_paymentMethod},
                              onSelectionChanged: (s) {
                                final m = s.first;
                                setState(() => _paymentMethod = m);
                                widget.cubit.setPaymentMethod(m);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceLG),
                        BrandSectionTitle(loc.bookingReviewItinerary),
                        const SizedBox(height: AppTheme.spaceSM),
                        _ItineraryCard(
                          pickup: widget.pickup,
                          destination: widget.destination,
                          pickupLabel: loc.bookingReviewPickupLabel,
                          destinationLabel: loc.bookingReviewDestinationLabel,
                          durationLabel: formatDurationMinutes(
                            widget.durationInMinutes,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceLG),
                        BrandSectionTitle(loc.bookingReviewTripDetails),
                        const SizedBox(height: AppTheme.spaceSM),
                        _DetailsCard(
                          rows: [
                            _DetailRow(
                              icon: Icons.schedule_rounded,
                              label: loc.bookingReviewDuration,
                              value: formatDurationMinutes(
                                widget.durationInMinutes,
                              ),
                              color: AppColor.secondaryColor,
                            ),
                            _DetailRow(
                              icon: Icons.group_rounded,
                              label: loc.bookingReviewTravelers,
                              value: '${widget.travelers}',
                              color: AppColor.accentColor,
                            ),
                            _DetailRow(
                              icon: Icons.translate_rounded,
                              label: loc.bookingReviewLanguage,
                              value: language.name,
                              color: AppColor.secondaryColor,
                            ),
                            _DetailRow(
                              icon: Icons.directions_car_rounded,
                              label: loc.bookingReviewCar,
                              value: widget.requiresCar
                                  ? loc.bookingReviewYes
                                  : loc.bookingReviewNo,
                              color: AppColor.warningColor,
                            ),
                          ],
                        ),
                        if ((widget.notes ?? '').isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spaceLG),
                          BrandSectionTitle(loc.bookingReviewNotes),
                          const SizedBox(height: AppTheme.spaceSM),
                          BrandCard(
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
                                    widget.notes!,
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
                        BrandSectionTitle(loc.bookingReviewPriceBreakdown),
                        const SizedBox(height: AppTheme.spaceSM),
                        if (breakdown != null)
                          PriceBreakdownCard(breakdown: breakdown)
                        else
                          _PriceEstimateFallback(
                            theme: theme,
                            loc: loc,
                            estimatedPrice: widget.helper.estimatedPrice,
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

class _PriceEstimateFallback extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations loc;
  final double estimatedPrice;

  const _PriceEstimateFallback({
    required this.theme,
    required this.loc,
    required this.estimatedPrice,
  });

  @override
  Widget build(BuildContext context) {
    final totalLabel = estimatedPrice <= 0
        ? '--'
        : 'EGP ${estimatedPrice.toStringAsFixed(0)}';
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Shimmer.fromColors(
            baseColor: BrandTokens.borderSoft,
            highlightColor: BrandTokens.bgSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColor.accentColor.withValues(alpha: 0.12),
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
                  loc.bookingReviewEstimatedTotal,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                totalLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColor.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          BrandOutlinedButton(
            label: loc.retry,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.bookingReviewPriceRetry)),
              );
            },
          ),
        ],
      ),
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
  final String pickupLabel;
  final String destinationLabel;
  final String durationLabel;
  const _ItineraryCard({
    required this.pickup,
    required this.destination,
    required this.pickupLabel,
    required this.destinationLabel,
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
            label: pickupLabel,
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
            label: destinationLabel,
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
  final bool visualEnabled;

  const _GradientCta({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
    this.visualEnabled = true,
  });

  @override
  State<_GradientCta> createState() => _GradientCtaState();
}

class _GradientCtaState extends State<_GradientCta> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    final muted = enabled && !widget.visualEnabled;
    final opacity = widget.isLoading ? 1.0 : (muted ? 0.55 : 1.0);
    return AnimatedScale(
      duration: const Duration(milliseconds: 90),
      scale: _down ? 0.98 : 1,
      child: Opacity(
        opacity: opacity,
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
              boxShadow: (enabled && widget.visualEnabled)
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
