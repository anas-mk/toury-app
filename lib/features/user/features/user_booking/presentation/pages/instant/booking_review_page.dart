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
import '../../../../../../../core/widgets/brand/mesh_gradient.dart';
import '../../../../../../../core/widgets/brand_widgets.dart';
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
  bool _mockCardAuthorized = false;
  bool _navigatedToWaiting = false;

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

  Future<void> _onConfirmPressed(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    if (!_canConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.bookingReviewValidationSnackbar)),
      );
      return;
    }
    if (_paymentMethod == AppPaymentMethod.mockCard && !_mockCardAuthorized) {
      final ok = await _showMockCardPrepaySheet(context);
      if (!ok || !context.mounted) return;
      setState(() => _mockCardAuthorized = true);
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
          if (_navigatedToWaiting) return;
          _navigatedToWaiting = true;
          final booking = state is InstantBookingCreated
              ? state.booking
              : (state as InstantBookingWaiting).booking;
          context.pushReplacement(
            AppRouter.instantWaiting.replaceFirst(':id', booking.bookingId),
            extra: InstantWaitingRouteArgs(
              cubit: context.read<InstantBookingCubit>(),
              helper: widget.helper,
            ),
          );
        }
      },
      builder: (context, state) {
        final loading = state is InstantBookingCreating;
        return Scaffold(
          backgroundColor: BrandTokens.bgSoft,
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
              SliverToBoxAdapter(
                child: _ReviewHero(
                  title: loc.bookingReviewTitle,
                  subtitle: loc.bookingReviewSubtitle,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceLG,
                    AppTheme.spaceMD,
                    AppTheme.spaceLG,
                    0,
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
                                icon: const Icon(
                                  Icons.payments_outlined,
                                  size: 18,
                                ),
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
                              setState(() {
                                _paymentMethod = m;
                                if (m == AppPaymentMethod.cash) {
                                  _mockCardAuthorized = false;
                                }
                              });
                              widget.cubit.setPaymentMethod(m);
                            },
                          ),
                        ),
                      ),
                      if (_paymentMethod == AppPaymentMethod.mockCard) ...[
                        const SizedBox(height: AppTheme.spaceSM),
                        _PrepayStatusCard(authorized: _mockCardAuthorized),
                      ],
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
            ],
          ),
        );
      },
    );
  }
}

Future<bool> _showMockCardPrepaySheet(BuildContext context) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => const _MockCardPrepaySheet(),
      ) ??
      false;
}

class _PrepayStatusCard extends StatelessWidget {
  final bool authorized;

  const _PrepayStatusCard({required this.authorized});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: authorized
            ? BrandTokens.successGreen.withValues(alpha: 0.09)
            : BrandTokens.accentAmber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: authorized
              ? BrandTokens.successGreen.withValues(alpha: 0.22)
              : BrandTokens.accentAmber.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Icon(
            authorized ? Icons.verified_rounded : Icons.lock_clock_rounded,
            color: authorized
                ? BrandTokens.successGreen
                : BrandTokens.accentAmberText,
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(
              authorized
                  ? 'Mock card authorized. Your request can now be sent.'
                  : 'Mock card must be authorized before we send the request to the helper.',
              style: BrandTokens.body(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: BrandTokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockCardPrepaySheet extends StatefulWidget {
  const _MockCardPrepaySheet();

  @override
  State<_MockCardPrepaySheet> createState() => _MockCardPrepaySheetState();
}

class _MockCardPrepaySheetState extends State<_MockCardPrepaySheet> {
  bool _processing = false;

  Future<void> _authorize() async {
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          decoration: BoxDecoration(
            color: BrandTokens.surfaceWhite,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: BrandTokens.shadowDeep,
                blurRadius: 40,
                spreadRadius: -12,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: BrandTokens.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: BrandTokens.ctaBlueGlow,
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Text(
                'Authorize mock card first',
                textAlign: TextAlign.center,
                style: BrandTokens.heading(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For card bookings, the user must pay before the helper receives the request. If the trip is cancelled later, this amount will be refunded to the wallet when backend wallet support is ready.',
                textAlign: TextAlign.center,
                style: BrandTokens.body(fontSize: 13, height: 1.55),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _processing ? null : _authorize,
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandTokens.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: _processing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_open_rounded),
                  label: Text(
                    _processing ? 'Authorizing...' : 'Authorize & continue',
                  ),
                ),
              ),
              TextButton(
                onPressed: _processing
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('Choose another payment method'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewHero extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ReviewHero({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ClipPath(
      clipper: _ReviewHeroClipper(),
      child: SizedBox(
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const MeshGradientBackground(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    BrandTokens.primaryBlueDark.withValues(alpha: 0.05),
                    BrandTokens.primaryBlueDark.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
            Positioned(
              top: top + 8,
              left: AppTheme.spaceMD,
              child: Material(
                color: Colors.white.withValues(alpha: 0.18),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppTheme.spaceLG,
              right: AppTheme.spaceLG,
              bottom: 46,
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.fact_check_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: BrandTokens.heading(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BrandTokens.body(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
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

class _ReviewHeroClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 42);
    p.cubicTo(
      size.width * 0.22,
      size.height - 8,
      size.width * 0.54,
      size.height - 76,
      size.width,
      size.height - 42,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandTokens.surfaceWhite,
            BrandTokens.primaryBlue.withValues(alpha: 0.035),
            BrandTokens.accentAmber.withValues(alpha: 0.055),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
        ),
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 30,
            spreadRadius: -10,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Hero(
                tag: 'helper-avatar-${helper.helperId}',
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: BrandTokens.amberGradient,
                  ),
                  child: AppNetworkImage(
                    imageUrl: helper.profileImageUrl,
                    width: 62,
                    height: 62,
                    borderRadius: 31,
                  ),
                ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BrandTokens.heading(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
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
                      style: BrandTokens.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: BrandTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      '${helper.completedTrips} trips',
                      style: BrandTokens.body(fontSize: 12),
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      '${helper.matchScore}% match',
                      style: BrandTokens.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: BrandTokens.successGreen,
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
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: BrandTokens.borderSoft.withValues(alpha: 0.8),
        ),
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 28,
            spreadRadius: -10,
            offset: Offset(0, 16),
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
                    child: Icon(rows[i].icon, color: rows[i].color, size: 18),
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
