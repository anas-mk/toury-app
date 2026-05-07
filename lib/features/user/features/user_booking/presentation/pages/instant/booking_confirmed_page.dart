import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/services/signalr/booking_hub_events.dart';
import '../../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../../core/widgets/brand/mesh_gradient.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';

/// Step 9 â€” green confirmation screen. Subscribes to `BookingTripStarted`
/// so we can push the live tracking screen when the helper begins the trip.
class BookingConfirmedPage extends StatefulWidget {
  final InstantBookingCubit cubit;
  final String bookingId;
  final HelperSearchResult? helper;

  const BookingConfirmedPage({
    super.key,
    required this.cubit,
    required this.bookingId,
    this.helper,
  });

  @override
  State<BookingConfirmedPage> createState() => _BookingConfirmedPageState();
}

class _BookingConfirmedPageState extends State<BookingConfirmedPage> {
  late final BookingTrackingHubService _hub;
  StreamSubscription<BookingTripStartedEvent>? _tripStartedSub;
  bool _tripNavigationDone = false;

  @override
  void initState() {
    super.initState();
    _hub = sl<BookingTrackingHubService>();
    _tripStartedSub = _hub.bookingTripStartedStream
        .where((e) => e.bookingId == widget.bookingId)
        .listen(_onTripStarted);
  }

  @override
  void dispose() {
    _tripStartedSub?.cancel();
    super.dispose();
  }

  void _onTripStarted(BookingTripStartedEvent event) {
    if (!mounted || _tripNavigationDone) return;
    _tripNavigationDone = true;
    context.pushReplacement(
      AppRouter.instantTripTracking.replaceFirst(':id', widget.bookingId),
      extra: InstantTripTrackingRouteArgs(
        cubit: widget.cubit,
        helper: widget.helper,
      ),
    );
  }

  Future<void> _openChat() async {
    context.push(AppRouter.userChat.replaceFirst(':id', widget.bookingId));
  }

  Future<void> _openPayment() async {
    context.push(
      AppRouter.paymentMethod.replaceFirst(':bookingId', widget.bookingId),
    );
  }

  Future<void> _callHelper(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<InstantBookingCubit, InstantBookingState>(
        builder: (context, state) {
          final booking = _bookingFrom(state);
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) context.go(AppRouter.home);
            },
            child: Scaffold(
              backgroundColor: BrandTokens.bgSoft,
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _ConfirmedHero(
                      onBack: () => context.go(AppRouter.home),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceLG,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HelperCard(
                              booking: booking,
                              helper: widget.helper,
                              onCall: _callHelper,
                              onChat: _openChat,
                              onPay: _openPayment,
                            ),
                            const SizedBox(height: AppTheme.spaceMD),
                            _NextMoveCard(
                              paymentRequired:
                                  booking?.paymentRequired ?? false,
                              onChat: _openChat,
                              onPay: _openPayment,
                            ),
                            if (booking != null) ...[
                              const SizedBox(height: AppTheme.spaceMD),
                              _TripSummary(booking: booking),
                            ],
                            const SizedBox(height: AppTheme.spaceLG),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  context.go(AppRouter.bookingHome),
                              icon: const Icon(Icons.home_rounded),
                              label: const Text('Back to home'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                foregroundColor: BrandTokens.primaryBlue,
                                side: BorderSide(
                                  color: BrandTokens.primaryBlue.withValues(
                                    alpha: 0.16,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusLG,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space2XL),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  BookingDetail? _bookingFrom(InstantBookingState s) {
    if (s is InstantBookingAccepted) return s.booking;
    if (s is InstantBookingWaiting) return s.booking;
    return null;
  }
}

class _ConfirmedHero extends StatelessWidget {
  final VoidCallback onBack;

  const _ConfirmedHero({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(
            clipper: _ConfirmedHeroClipper(),
            child: const MeshGradientBackground(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BrandTokens.primaryBlueDark.withValues(alpha: 0.08),
                  BrandTokens.primaryBlueDark.withValues(alpha: 0.44),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 8,
            left: AppTheme.spaceMD,
            child: _GlassCircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
          ),
          Positioned(
            left: AppTheme.spaceLG,
            right: AppTheme.spaceLG,
            top: top + 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: BrandTokens.accentAmber,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'HELPER ACCEPTED',
                        style: BrandTokens.body(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMD),
                Text(
                  'Your trip is locked in',
                  style: BrandTokens.heading(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chat with your helper, finish payment, and follow realtime trip updates from here.',
                  style: BrandTokens.body(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.84),
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

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _ConfirmedHeroClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 58);
    p.cubicTo(
      size.width * 0.22,
      size.height - 12,
      size.width * 0.58,
      size.height - 96,
      size.width,
      size.height - 46,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HelperCard extends StatelessWidget {
  final BookingDetail? booking;
  final HelperSearchResult? helper;
  final void Function(String phone) onCall;
  final VoidCallback onChat;
  final VoidCallback onPay;
  const _HelperCard({
    required this.booking,
    required this.helper,
    required this.onCall,
    required this.onChat,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final summary = booking?.helper;
    final name = summary?.fullName ?? helper?.fullName ?? 'Your helper';
    final avatar = summary?.profileImageUrl ?? helper?.profileImageUrl;
    final phone = summary?.phoneNumber;
    final paymentRequired = booking?.paymentRequired ?? false;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandTokens.surfaceWhite,
            BrandTokens.primaryBlue.withValues(alpha: 0.035),
            BrandTokens.accentAmber.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
        ),
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowDeep,
            blurRadius: 38,
            spreadRadius: -14,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Hero(
                    tag:
                        'helper-avatar-${summary?.helperId ?? helper?.helperId ?? 'confirmed'}',
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: BrandTokens.amberGradient,
                      ),
                      child: AppNetworkImage(
                        imageUrl: avatar,
                        width: 72,
                        height: 72,
                        borderRadius: 36,
                      ),
                    ),
                  ),
                  const Positioned(
                    right: -3,
                    bottom: -3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: BrandTokens.successGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
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
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BrandTokens.heading(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verified guide is ready for your trip',
                      style: BrandTokens.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((phone ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(phone!, style: BrandTokens.body(fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.phone_rounded,
                  label: 'Call',
                  color: AppColor.secondaryColor,
                  onTap: (phone ?? '').isEmpty ? null : () => onCall(phone!),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  color: AppColor.accentColor,
                  onTap: onChat,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: _ActionButton(
                  icon: Icons.payment_rounded,
                  label: 'Pay',
                  color: AppColor.warningColor,
                  highlighted: paymentRequired,
                  onTap: onPay,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextMoveCard extends StatelessWidget {
  final bool paymentRequired;
  final VoidCallback onChat;
  final VoidCallback onPay;

  const _NextMoveCard({
    required this.paymentRequired,
    required this.onChat,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: BrandTokens.primaryBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: BrandTokens.ctaBlueGlow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BrandTokens.accentAmber,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              paymentRequired ? Icons.payments_rounded : Icons.chat_rounded,
              color: BrandTokens.primaryBlue,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paymentRequired ? 'Payment is next' : 'You are ready to go',
                  style: BrandTokens.heading(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  paymentRequired
                      ? 'Finish payment now or chat with your helper first.'
                      : 'Open chat for pickup notes and live coordination.',
                  style: BrandTokens.body(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: paymentRequired ? onPay : onChat,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool highlighted;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: highlighted
                ? const LinearGradient(
                    colors: [BrandTokens.accentAmber, Color(0xFFFFC04A)],
                  )
                : null,
            color: highlighted ? null : color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Opacity(
            opacity: disabled ? 0.4 : 1,
            child: Column(
              children: [
                Icon(
                  icon,
                  color: highlighted ? BrandTokens.primaryBlue : color,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: highlighted ? BrandTokens.primaryBlue : color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripSummary extends StatelessWidget {
  final BookingDetail booking;
  const _TripSummary({required this.booking});

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
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(
            theme,
            Icons.trip_origin_rounded,
            AppColor.accentColor,
            'Pickup',
            booking.pickupLocationName,
          ),
          if ((booking.destinationName ?? '').isNotEmpty)
            _line(
              theme,
              Icons.flag_rounded,
              AppColor.errorColor,
              'Destination',
              booking.destinationName!,
            ),
          _line(
            theme,
            Icons.schedule_rounded,
            AppColor.secondaryColor,
            'Duration',
            '${booking.durationInMinutes} minutes',
          ),
          _line(
            theme,
            Icons.group_rounded,
            AppColor.accentColor,
            'Travelers',
            '${booking.travelersCount}',
          ),
          if (booking.estimatedPrice != null)
            _line(
              theme,
              Icons.payments_rounded,
              AppColor.warningColor,
              'Estimated',
              'EGP ${booking.estimatedPrice!.toStringAsFixed(0)}',
            ),
        ],
      ),
    );
  }

  Widget _line(
    ThemeData theme,
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColor.lightTextSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
