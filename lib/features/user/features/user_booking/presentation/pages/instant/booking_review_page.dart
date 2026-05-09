import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/localization/app_localizations.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/services/realtime/app_realtime_cubit.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/utils/number_format.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/app_payment_method.dart';
import '../../../domain/entities/create_instant_booking_request.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import '../../widgets/instant/duration_picker_sheet.dart';
import 'location_label_format.dart';
import 'location_pick_result.dart';

/// Step 6 — Confirm Booking (Pass #6 — 2026 editorial redesign).
///
/// Shows a clean summary of the upcoming booking (helper · journey ·
/// total price) and lets the user fire `POST /user/bookings/instant`.
///
/// Design highlights (matches the RAFIQ HTML mockup):
///   • Cream `#FAF8F4` background, flat sticky top bar.
///   • Page title "Confirm Booking" in primary blue.
///   • Helper mini card (avatar 64 + name + ★ rating + reviews).
///   • Journey visualization with two endpoint pills connected by a
///     dotted line, plus distance · duration · scheduled-for chips.
///   • Single price block — JUST the total (no payment selector and no
///     fee breakdown, by product request).
///   • Sticky pill CTA "Confirm & Request" that creates the booking
///     and routes to the WaitingForHelperPage.
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

  void _onPaymentMethodChanged(AppPaymentMethod method) {
    if (method == _paymentMethod) return;
    HapticFeedback.selectionClick();
    setState(() {
      _paymentMethod = method;
      // Switching back to cash invalidates any prior mock card
      // authorization the user might have done on this screen.
      if (method == AppPaymentMethod.cash) {
        _mockCardAuthorized = false;
      }
    });
    widget.cubit.setPaymentMethod(method);
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
    HapticFeedback.mediumImpact();
    _fireCreate(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
          // Tell the home-level cubits to re-fetch so the active-trip
          // banner appears immediately when the user navigates home
          // (instead of only after a manual pull-to-refresh).
          sl<AppRealtimeCubit>().notifyBookingCreated(booking.bookingId);
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
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFFFBF8FF),
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                const SliverAppBar(
                  pinned: true,
                  floating: false,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  automaticallyImplyLeading: false,
                  centerTitle: false,
                  backgroundColor: Color(0xFFFBF8FF),
                  surfaceTintColor: Color(0xFFFBF8FF),
                  toolbarHeight: 64,
                  titleSpacing: 0,
                  title: _TopBarRow(),
                ),
                SliverToBoxAdapter(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.bookingReviewTitle,
                            style: BrandTokens.heading(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: BrandTokens.primaryBlue,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _HelperMiniCard(helper: widget.helper),
                          const SizedBox(height: 24),
                          _JourneyCard(
                            pickup: widget.pickup,
                            destination: widget.destination,
                            durationInMinutes: widget.durationInMinutes,
                          ),
                          const SizedBox(height: 24),
                          _PriceCard(
                            estimatedPrice: widget.helper.estimatedPrice,
                          ),
                          const SizedBox(height: 24),
                          _PaymentSelector(
                            value: _paymentMethod,
                            onChanged: _onPaymentMethodChanged,
                          ),
                          if (_paymentMethod == AppPaymentMethod.mockCard) ...[
                            const SizedBox(height: 12),
                            _PrepayStatusCard(
                              authorized: _mockCardAuthorized,
                            ),
                          ],
                          if ((widget.notes ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _NotesCard(text: widget.notes!),
                          ],
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _ConfirmDock(
              loading: loading,
              enabled: _canConfirm && !loading,
              onTap: () => _onConfirmPressed(context),
              label: loading
                  ? loc.bookingReviewConfirmLoading
                  : loc.bookingReviewConfirm,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBarRow extends StatelessWidget {
  const _TopBarRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.selectionClick();
                context.pop();
              },
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF767683),
                  size: 22,
                ),
              ),
            ),
          ),
          Text(
            BrandTokens.wordmark,
            style: BrandTokens.heading(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: BrandTokens.primaryBlue,
              letterSpacing: -1.0,
            ),
          ),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.selectionClick();
                final ctrl = PrimaryScrollController.maybeOf(context);
                if (ctrl != null && ctrl.hasClients) {
                  ctrl.animateTo(
                    0,
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.explore_outlined,
                  color: Color(0xFF767683),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper mini card (avatar + name + rating)
// ─────────────────────────────────────────────────────────────────────────────

class _HelperMiniCard extends StatelessWidget {
  final HelperSearchResult helper;
  const _HelperMiniCard({required this.helper});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 30,
            spreadRadius: -8,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'helper-avatar-${helper.helperId}',
            child: ClipOval(
              child: AppNetworkImage(
                imageUrl: helper.profileImageUrl,
                width: 64,
                height: 64,
                borderRadius: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  helper.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BrandTokens.heading(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: BrandTokens.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Color(0xFF924C00),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${context.localizeNumber(helper.rating, decimals: 1)} '
                      '(${context.localizeNumber(helper.completedTrips)} reviews)',
                      style: const TextStyle(
                        color: Color(0xFF464652),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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

// ─────────────────────────────────────────────────────────────────────────────
// Journey card (pickup pill — line — destination pill, with chips below)
// ─────────────────────────────────────────────────────────────────────────────

class _JourneyCard extends StatelessWidget {
  final LocationPickResult pickup;
  final LocationPickResult destination;
  final int durationInMinutes;
  const _JourneyCard({
    required this.pickup,
    required this.destination,
    required this.durationInMinutes,
  });

  /// Coarse great-circle distance for display purposes only. The
  /// authoritative figure comes from the backend during actual
  /// pricing / tracking.
  double _haversineKm() {
    const r = 6371.0;
    final dLat = _toRad(destination.latitude - pickup.latitude);
    final dLng = _toRad(destination.longitude - pickup.longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(pickup.latitude)) *
            math.cos(_toRad(destination.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * (math.pi / 180.0);

  String _formatDistance(BuildContext context, double km) {
    if (km < 1) return '${context.localizeNumber((km * 1000).round())} m';
    return '${context.localizeNumber(km, decimals: 1)} km';
  }

  String _formatDuration(BuildContext context, int m) {
    if (m % 60 == 0) {
      final h = m ~/ 60;
      return h == 1
          ? '${context.localizeNumber(h)} hour'
          : '${context.localizeNumber(h)} hours';
    }
    return '${context.localizeNumber(m ~/ 60)}h ${context.localizeNumber(m % 60)}m';
  }

  String _scheduledLabel(BuildContext context) {
    // The instant flow always means "now" — surface it as a friendly
    // human label so the user feels confident they pressed the right
    // button. (A scheduled flow would replace this string upstream.)
    final now = TimeOfDay.now();
    final hour12 = ((now.hour + 11) % 12) + 1;
    final am = now.hour < 12;
    final mm = now.minute.toString().padLeft(2, '0');
    return 'Today at ${context.localizeNumber(hour12)}:'
        '${context.localizeDigits(mm)} ${am ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final km = _haversineKm();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 30,
            spreadRadius: -8,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _RouteVisual(pickup: pickup, destination: destination),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              _MetaChip(text: _formatDistance(context, km)),
              const _Dot(),
              _MetaChip(text: _formatDuration(context, durationInMinutes)),
              const _Dot(),
              _MetaChip(text: _scheduledLabel(context)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteVisual extends StatelessWidget {
  final LocationPickResult pickup;
  final LocationPickResult destination;
  const _RouteVisual({required this.pickup, required this.destination});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Connecting line.
          const Positioned(
            left: 60,
            right: 60,
            top: 20,
            child: SizedBox(
              height: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFE4E1EA),
                ),
              ),
            ),
          ),
          // Endpoints.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Endpoint(
                icon: Icons.location_on_rounded,
                background: const Color(0xFF1B237E),
                foreground: const Color(0xFF8790EE),
                label: LocationLabel.shortChip(pickup, fallback: 'Pickup'),
              ),
              _Endpoint(
                icon: Icons.account_balance_rounded,
                background: const Color(0xFF924C00),
                foreground: Colors.white,
                label: LocationLabel.shortChip(
                  destination,
                  fallback: 'Destination',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final String label;
  const _Endpoint({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Adds white "padding" around the dot so the connecting line
      // visually breaks at the endpoint (matches the mockup).
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: foreground, size: 22),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF464652),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;
  const _MetaChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF464652),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: Color(0xFFC6C5D4),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Price card (just the total — no breakdown, by request)
// ─────────────────────────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final double estimatedPrice;
  const _PriceCard({required this.estimatedPrice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 30,
            spreadRadius: -8,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    color: Color(0xFF767683),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Estimated for this trip',
                  style: const TextStyle(
                    color: Color(0xFF464652),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${context.localizeNumber(estimatedPrice, decimals: 0)} EGP',
            style: BrandTokens.heading(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: BrandTokens.primaryBlue,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment selector (Cash / Mock Card) + prepay info banner
//
// We use two side-by-side selectable tiles instead of Flutter's
// `SegmentedButton` so the visual weight matches the rest of the
// editorial design (rounded 16px tiles, soft shadow on selection,
// brand-blue accent border, color-tinted icon plates). The whole
// thing is animated so switching feels alive without being noisy.
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentSelector extends StatelessWidget {
  final AppPaymentMethod value;
  final ValueChanged<AppPaymentMethod> onChanged;
  const _PaymentSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 30,
            spreadRadius: -8,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAYMENT METHOD',
            style: TextStyle(
              color: Color(0xFF767683),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PaymentOption(
                  icon: Icons.payments_rounded,
                  title: 'Cash',
                  subtitle: 'Pay after the trip',
                  selected: value == AppPaymentMethod.cash,
                  onTap: () => onChanged(AppPaymentMethod.cash),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PaymentOption(
                  icon: Icons.credit_card_rounded,
                  title: 'Card',
                  subtitle: 'Authorize now',
                  selected: value == AppPaymentMethod.mockCard,
                  onTap: () => onChanged(AppPaymentMethod.mockCard),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = BrandTokens.primaryBlue;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.06)
                : const Color(0xFFFBF8FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? accent
                  : const Color(0xFFE4E1EA),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected
                          ? accent
                          : accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? Colors.white : accent,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? accent : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? accent
                            : const Color(0xFFC6C5D4),
                        width: 1.6,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: BrandTokens.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF464652),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrepayStatusCard extends StatelessWidget {
  final bool authorized;
  const _PrepayStatusCard({required this.authorized});

  @override
  Widget build(BuildContext context) {
    final fg = authorized
        ? BrandTokens.successGreen
        : BrandTokens.accentAmberText;
    final bg = authorized
        ? BrandTokens.successGreen.withValues(alpha: 0.10)
        : BrandTokens.accentAmber.withValues(alpha: 0.12);
    final border = authorized
        ? BrandTokens.successGreen.withValues(alpha: 0.25)
        : BrandTokens.accentAmber.withValues(alpha: 0.32);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            authorized
                ? Icons.verified_rounded
                : Icons.lock_clock_rounded,
            color: fg,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              authorized
                  ? 'Card authorized — your request is ready to send.'
                  : 'You\'ll authorize the card before we notify the helper.',
              style: TextStyle(
                color: BrandTokens.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal sheet that asks the user to authorize a "mock" card before
/// the booking is sent — kept minimal and on-brand. Resolves to
/// `true` when the user confirms.
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

class _MockCardPrepaySheet extends StatefulWidget {
  const _MockCardPrepaySheet();

  @override
  State<_MockCardPrepaySheet> createState() => _MockCardPrepaySheetState();
}

class _MockCardPrepaySheetState extends State<_MockCardPrepaySheet> {
  bool _processing = false;

  Future<void> _authorize() async {
    setState(() => _processing = true);
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: BrandTokens.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          BrandTokens.primaryBlue.withValues(alpha: 0.32),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Authorize your card',
                textAlign: TextAlign.center,
                style: BrandTokens.heading(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: BrandTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For card bookings, the helper is only notified after '
                'we authorize your card. If the trip is cancelled, the '
                'amount will be refunded to your wallet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BrandTokens.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Material(
                  color: BrandTokens.primaryBlue,
                  borderRadius: BorderRadius.circular(40),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: _processing ? null : _authorize,
                    child: Center(
                      child: _processing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_open_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Authorize & continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _processing
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: BrandTokens.textSecondary,
                ),
                child: const Text(
                  'Choose another payment method',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notes (only when the user added some)
// ─────────────────────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  final String text;
  const _NotesCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 30,
            spreadRadius: -8,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.note_alt_rounded,
            color: Color(0xFF767683),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NOTES',
                  style: TextStyle(
                    color: Color(0xFF767683),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF1B1B21),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky CTA dock (gradient fade + filled pill button)
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmDock extends StatelessWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;
  final String label;
  const _ConfirmDock({
    required this.loading,
    required this.enabled,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xFFFBF8FF),
            Color(0xE6FBF8FF),
            Color(0x00FBF8FF),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: _ConfirmButton(
            loading: loading,
            enabled: enabled,
            onTap: onTap,
            label: label,
          ),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatefulWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;
  final String label;
  const _ConfirmButton({
    required this.loading,
    required this.enabled,
    required this.onTap,
    required this.label,
  });

  @override
  State<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<_ConfirmButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: widget.enabled || widget.loading ? 1.0 : 0.55,
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _down = true)
              : null,
          onTapCancel: widget.enabled
              ? () => setState(() => _down = false)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _down = false)
              : null,
          onTap: widget.enabled ? widget.onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: BrandTokens.primaryBlue,
              borderRadius: BorderRadius.circular(40),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color:
                            BrandTokens.primaryBlue.withValues(alpha: 0.30),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: widget.loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
