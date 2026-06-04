import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubits/scheduled/scheduled_booking_detail_cubit.dart';
import '../../domain/entities/booking_detail.dart';
import '../../../../../../core/widgets/app_network_image.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kNavy        = Color(0xFF000668);
const _kBlue        = Color(0xFF4851C4);
const _kAmber       = Color(0xFFC96B00);
const _kBg          = Color(0xFFFBF8FF);
const _kCard        = Color(0xFFFFFFFF);
const _kMuted       = Color(0xFF767683);
const _kOnSurface   = Color(0xFF1A1B25);
const _kOutline     = Color(0xFFC6C5D3);
const _kSuccess     = Color(0xFF1DB97A);

const _kGradient = LinearGradient(
  colors: [_kNavy, _kBlue],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

/// Journey-complete receipt screen shown after a trip ends.
/// Routes here from TripEnded notification (when payment is not pending).
/// After the user taps "Rate Experience", the MandatoryRatingOverlay
/// that was already enqueued by AppRealtimeCubit will surface automatically.
class TripReceiptPage extends StatelessWidget {
  final String bookingId;
  const TripReceiptPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScheduledBookingDetailCubit>(
      create: (_) => sl<ScheduledBookingDetailCubit>()..load(bookingId),
      child: _ReceiptBody(bookingId: bookingId),
    );
  }
}

class _ReceiptBody extends StatefulWidget {
  final String bookingId;
  const _ReceiptBody({required this.bookingId});

  @override
  State<_ReceiptBody> createState() => _ReceiptBodyState();
}

class _ReceiptBodyState extends State<_ReceiptBody> {
  // markPending is intentionally NOT called here.
  // It is handled by:
  //   1. AppRealtimeCubit when BusBookingTripEnded fires (app is live).
  //   2. TripTrackingPage._onTripEnded (live tracking path).
  //   3. NotificationRouter.routeFromData for cold-start FCM TripEnded taps.
  // Calling it here on every initState would re-add already-submitted ratings.

  @override
  Widget build(BuildContext context) {
    final topPad    = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: BlocBuilder<ScheduledBookingDetailCubit, ScheduledBookingDetailState>(
        builder: (context, state) {
          final booking = state is ScheduledBookingDetailLoaded
              ? state.booking
              : null;

          return Stack(
            children: [
              // ── Topographic background ──────────────────────────────────
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _TopoPainter()),
                ),
              ),

              // ── Scrollable content ──────────────────────────────────────
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: topPad + 64)),

                  // "JOURNEY COMPLETE" stamp
                  SliverToBoxAdapter(
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.21,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: _kAmber, width: 2.5),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: _kAmber,
                                size: 26,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'JOURNEY COMPLETE',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _kAmber,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Receipt card ────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: booking == null
                          ? _LoadingCard()
                          : _ReceiptCard(booking: booking),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 40 + bottomPad)),
                ],
              ),

              // ── Fixed header ────────────────────────────────────────────
              _Header(topPad: topPad),
            ],
          );
        },
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double topPad;
  const _Header({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 12),
        decoration: BoxDecoration(
          color: _kBg.withValues(alpha: 0.88),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0E1B237E),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.go(AppRouter.home);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _kCard,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0E1B237E),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: _kOnSurface,
                  size: 20,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'RAFIQ',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _kNavy,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

// ── Receipt card ──────────────────────────────────────────────────────────────

class _ReceiptCard extends StatelessWidget {
  final BookingDetail booking;
  const _ReceiptCard({required this.booking});

  String _fmtDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _durationLabel(int mins) {
    if (mins >= 480) return 'Full Day';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final shortRef = booking.bookingId.length > 8
        ? booking.bookingId.substring(0, 8).toUpperCase()
        : booking.bookingId.toUpperCase();
    final helperName = booking.helper?.fullName ??
        booking.currentAssignment?.helperName ?? 'Your Guide';
    final price      = booking.finalPrice ?? booking.estimatedPrice;
    final completedDate = booking.completedAt ?? booking.requestedDate;

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0x121B237E),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card header: helper avatar + title ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              children: [
                // Helper avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _kCard, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: _kNavy.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: booking.helper?.profileImageUrl != null
                        ? AppNetworkImage(
                            imageUrl: booking.helper!.profileImageUrl,
                            width: 72,
                            height: 72,
                            borderRadius: 36,
                          )
                        : Container(
                            color: const Color(0xFFEEEAFB),
                            alignment: Alignment.center,
                            child: Text(
                              helperName.isNotEmpty
                                  ? helperName[0].toUpperCase()
                                  : 'G',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: _kNavy,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Official Receipt',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _kNavy,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Booking #$shortRef',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: _kMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                if (completedDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _fmtDate(completedDate.toLocal()),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: _kMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
              ],
            ),
          ),

          // ── Perforated top divider ──────────────────────────────────────
          _PerforatedDivider(),

          // ── Line items ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              children: [
                _LineItem(
                  label: 'Guide',
                  value: helperName,
                  icon: Icons.person_rounded,
                ),
                if (booking.requestedDate != null) ...[
                  const SizedBox(height: 12),
                  _LineItem(
                    label: 'Trip Date',
                    value: _fmtDate(booking.requestedDate!),
                    icon: Icons.calendar_today_outlined,
                  ),
                ],
                const SizedBox(height: 12),
                _LineItem(
                  label: 'Duration',
                  value: _durationLabel(booking.durationInMinutes),
                  icon: Icons.hourglass_bottom_rounded,
                ),
                const SizedBox(height: 12),
                _LineItem(
                  label: 'Travelers',
                  value: '${booking.travelersCount} pax',
                  icon: Icons.people_alt_outlined,
                ),
                if (booking.depositAmount != null) ...[
                  const SizedBox(height: 12),
                  _LineItem(
                    label: 'Deposit',
                    value: 'EGP ${booking.depositAmount!.toStringAsFixed(0)}',
                    icon: Icons.payments_outlined,
                    trailing: booking.depositPaid
                        ? _PaidBadge()
                        : null,
                  ),
                ],
                if (booking.remainingAmount != null &&
                    booking.remainingAmount! > 0) ...[
                  const SizedBox(height: 12),
                  _LineItem(
                    label: 'Remaining',
                    value: 'EGP ${booking.remainingAmount!.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_outlined,
                    trailing: booking.remainingPaid
                        ? _PaidBadge()
                        : null,
                  ),
                ],
              ],
            ),
          ),

          // ── Perforated bottom divider ───────────────────────────────────
          _PerforatedDivider(),

          // ── Total pill ──────────────────────────────────────────────────
          if (price != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: _kMuted,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: _kGradient,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'EGP ${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Payment confirmation ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F2FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.credit_card_rounded,
                    size: 20,
                    color: _kMuted,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Payment settled',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: _kOnSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: _kSuccess,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'PAID',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _kSuccess,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading card skeleton ─────────────────────────────────────────────────────

class _LoadingCard extends StatefulWidget {
  @override
  State<_LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<_LoadingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final shimmer = Color.lerp(
          const Color(0xFFE8E6F0),
          const Color(0xFFF5F3FF),
          _ctrl.value,
        )!;
        return Container(
          height: 400,
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0x121B237E),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: shimmer,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 20,
                  width: 160,
                  decoration: BoxDecoration(
                    color: shimmer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: shimmer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(
                  4,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _LineItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Widget? trailing;
  const _LineItem({
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F2FF),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: _kBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  color: _kMuted,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kOnSurface,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _PaidBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'PAID',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _kSuccess,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Perforated divider ────────────────────────────────────────────────────────

class _PerforatedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dashed line
          Positioned.fill(
            child: CustomPaint(painter: _DashPainter()),
          ),
          // Left notch
          Positioned(
            left: -12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _kBg,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Right notch
          Positioned(
            right: -12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _kBg,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kOutline
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashW = 8.0;
    const gapW  = 5.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashW, y), paint);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}


// ── Topographic background painter ───────────────────────────────────────────

class _TopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE4E1E9).withValues(alpha: 0.35)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 6; i++) {
      final r = size.width * 0.18 * i;
      canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.1), r, paint);
    }
    for (int i = 1; i <= 5; i++) {
      final r = size.width * 0.20 * i;
      canvas.drawCircle(
        Offset(size.width * 0.9, size.height * 0.75),
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
