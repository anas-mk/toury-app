import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../../../../core/services/realtime/app_realtime_cubit.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/utils/jwt_payload.dart';
import '../../../../../../core/widgets/booking_status_chip.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../cubits/my_bookings_cubit.dart';
import '../cubits/my_bookings_state.dart';

// ─── Filter ──────────────────────────────────────────────────────────────────

enum _Filter { active, upcoming, past }

bool _isActive(BookingStatus s) =>
    s == BookingStatus.pendingHelperResponse ||
    s == BookingStatus.acceptedByHelper ||
    s == BookingStatus.confirmedAwaitingPayment ||
    s == BookingStatus.inProgress ||
    s == BookingStatus.reassignmentInProgress ||
    s == BookingStatus.waitingForUserAction;

bool _isUpcoming(BookingStatus s) =>
    s == BookingStatus.confirmedPaid || s == BookingStatus.upcoming;

bool _isPast(BookingStatus s) =>
    s == BookingStatus.completed ||
    s == BookingStatus.declinedByHelper ||
    s == BookingStatus.expiredNoResponse ||
    s == BookingStatus.cancelledByUser ||
    s == BookingStatus.cancelledByHelper ||
    s == BookingStatus.cancelledBySystem;

// ─── Page ────────────────────────────────────────────────────────────────────

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  MyBookingsCubit? _registeredCubit;
  _Filter _filter = _Filter.active;
  String? _firstName;

  @override
  void initState() {
    super.initState();
    try {
      final token = sl<AuthService>().getToken();
      final name = JwtPayload.firstName(token);
      if (name != null && name.isNotEmpty) {
        _firstName = name[0].toUpperCase() + name.substring(1);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    final c = _registeredCubit;
    if (c != null) {
      sl<AppRealtimeCubit>().unregisterMyBookings(c);
      _registeredCubit = null;
    }
    super.dispose();
  }

  List<BookingDetailEntity> _apply(List<BookingDetailEntity> all) =>
      switch (_filter) {
        _Filter.active   => all.where((b) => _isActive(b.status)).toList(),
        _Filter.upcoming => all.where((b) => _isUpcoming(b.status)).toList(),
        _Filter.past     => all.where((b) => _isPast(b.status)).toList(),
      };

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<MyBookingsCubit>()..getBookings(pageSize: 30);
        _registeredCubit = cubit;
        sl<AppRealtimeCubit>().registerMyBookings(cubit);
        return cubit;
      },
      child: Scaffold(
        backgroundColor: BrandTokens.bgSoft,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _TopBar(firstName: _firstName),
              Expanded(
                child: BlocBuilder<MyBookingsCubit, MyBookingsState>(
                  builder: (context, state) {
                    if (state is MyBookingsLoading ||
                        state is MyBookingsInitial) {
                      return const _Skeleton();
                    }
                    if (state is MyBookingsError) {
                      return _ErrorView(
                        message: state.message,
                        onRetry: () => context
                            .read<MyBookingsCubit>()
                            .refreshBookings(pageSize: 30),
                      );
                    }
                    if (state is MyBookingsLoaded) {
                      final filtered = _apply(state.bookings);
                      return RefreshIndicator.adaptive(
                        color: BrandTokens.primaryBlue,
                        onRefresh: () => context
                            .read<MyBookingsCubit>()
                            .refreshBookings(pageSize: 30),
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(
                              child: _Header(
                                current: _filter,
                                onChange: (f) => setState(() => _filter = f),
                              ),
                            ),
                            if (filtered.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _EmptyState(filter: _filter),
                              )
                            else
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 0, 24, 120),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (_, i) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: _BookingCard(
                                        booking: filtered[i],
                                      ),
                                    ),
                                    childCount: filtered.length,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String? firstName;
  const _TopBar({this.firstName});

  @override
  Widget build(BuildContext context) {
    final initial = (firstName?.isNotEmpty ?? false)
        ? firstName![0].toUpperCase()
        : null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // User avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: initial != null
                ? Text(
                    initial,
                    style: BrandTokens.heading(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: BrandTokens.primaryBlue,
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    color: BrandTokens.primaryBlue,
                    size: 22,
                  ),
          ),

          const Spacer(),

          // RAFIQ wordmark
          const Text(
            'RAFIQ',
            style: TextStyle(
              inherit: false,
              fontFamily: 'PermanentMarker',
              fontSize: 28,
              color: BrandTokens.primaryBlue,
            ),
          ),

          const Spacer(),

          // Explore icon
          GestureDetector(
            onTap: () => HapticFeedback.selectionClick(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.explore_outlined,
                color: BrandTokens.primaryBlue,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Headline + filter chips ─────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final _Filter current;
  final ValueChanged<_Filter> onChange;
  const _Header({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Journeys',
            style: BrandTokens.heading(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: BrandTokens.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _Chip(
                  label: 'Active',
                  selected: current == _Filter.active,
                  onTap: () => onChange(_Filter.active),
                ),
                const SizedBox(width: 10),
                _Chip(
                  label: 'Upcoming',
                  selected: current == _Filter.upcoming,
                  onTap: () => onChange(_Filter.upcoming),
                ),
                const SizedBox(width: 10),
                _Chip(
                  label: 'Past',
                  selected: current == _Filter.past,
                  onTap: () => onChange(_Filter.past),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? BrandTokens.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: selected ? BrandTokens.primaryBlue : BrandTokens.borderSoft,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: BrandTokens.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : BrandTokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Booking card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final BookingDetailEntity booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final active = _isActive(booking.status);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.pushNamed(
          'booking-details',
          pathParameters: {'id': booking.id},
          extra: {'booking': booking},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: BrandTokens.primaryBlue.withValues(alpha: 0.07),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RouteCard(booking: booking),
                  _CardContent(booking: booking),
                ],
              ),
              // Left accent stripe for in-flight bookings
              if (active)
                Positioned(
                  top: 0,
                  left: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: const BoxDecoration(
                      gradient: BrandTokens.primaryGradient,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Route card header ─────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final BookingDetailEntity booking;
  const _RouteCard({required this.booking});

  static const _palettes = [
    [Color(0xFF1B237E), Color(0xFF3949AB)],
    [Color(0xFF0D47A1), Color(0xFF1565C0)],
    [Color(0xFF283593), Color(0xFF3F51B5)],
    [Color(0xFF004D40), Color(0xFF00796B)],
  ];

  static String _dur(int m) {
    if (m <= 0) return '--';
    if (m < 60) return '${m}m';
    if (m % 60 == 0) return '${m ~/ 60}h';
    return '${m ~/ 60}h ${m % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final seed = booking.destinationCity.isNotEmpty
        ? booking.destinationCity.codeUnitAt(0)
        : 0;
    final colors = _palettes[seed % _palettes.length];
    final isScheduled = booking.type == BookingType.scheduled;

    final pickup = (booking.pickupLocationName?.split(',').first.trim()) ??
        'Your Location';
    final dest =
        (booking.destinationName ?? booking.destinationCity).split(',').first.trim();

    return SizedBox(
      height: 152,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Gradient background ──────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
          ),

          // ── Decorative map rings ──────────────────────────────────
          Positioned(
            right: -30,
            top: -30,
            child: _MapRing(size: 140),
          ),
          Positioned(
            left: -20,
            bottom: -40,
            child: _MapRing(size: 100),
          ),

          // ── Route visualization ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Travel mode icon
                Icon(
                  isScheduled
                      ? Icons.flight_rounded
                      : Icons.directions_car_filled_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 18,
                ),
                const SizedBox(height: 6),

                // Origin ── dashed line ── Destination
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.40),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomPaint(
                        size: const Size(double.infinity, 2),
                        painter: _DashPainter(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 7),

                // City names + duration pill
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pickup,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        _dur(booking.durationInMinutes),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        dest,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Bottom fade for badge legibility ─────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x44000000)],
                ),
              ),
            ),
          ),

          // ── Status badge ──────────────────────────────────────────
          Positioned(
            top: 10,
            left: 14,
            child: _Badge(booking: booking),
          ),
        ],
      ),
    );
  }
}

class _MapRing extends StatelessWidget {
  final double size;
  const _MapRing({required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Container(
            width: size * 0.55,
            height: size * 0.55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1.5,
              ),
            ),
          ),
        ),
      );
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashW = 6.0;
    const gap = 4.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset((x + dashW).clamp(0, size.width), y), paint);
      x += dashW + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}

class _Badge extends StatelessWidget {
  final BookingDetailEntity booking;
  const _Badge({required this.booking});

  String? get _label {
    switch (booking.status) {
      case BookingStatus.inProgress:
        return 'ONGOING';
      case BookingStatus.waitingForUserAction:
        return 'ACTION NEEDED';
      case BookingStatus.pendingHelperResponse:
      case BookingStatus.reassignmentInProgress:
        return 'FINDING GUIDE';
      case BookingStatus.acceptedByHelper:
        return 'GUIDE ASSIGNED';
      case BookingStatus.confirmedAwaitingPayment:
        return 'AWAITING PAYMENT';
      case BookingStatus.confirmedPaid:
      case BookingStatus.upcoming:
        final diff =
            booking.requestedDate.toLocal().difference(DateTime.now());
        if (diff.inDays == 0) return 'TODAY';
        if (diff.inDays == 1) return 'TOMORROW';
        return DateFormat('MMM d')
            .format(booking.requestedDate.toLocal())
            .toUpperCase();
      case BookingStatus.completed:
        return DateFormat('MMM d')
            .format(booking.requestedDate.toLocal())
            .toUpperCase();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        label,
        style: BrandTokens.heading(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: BrandTokens.primaryBlue,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Content section ───────────────────────────────────────────────────────────

class _CardContent extends StatelessWidget {
  final BookingDetailEntity booking;
  const _CardContent({required this.booking});

  @override
  Widget build(BuildContext context) {
    final destination = booking.destinationName ?? booking.destinationCity;
    final price = booking.finalPrice ?? booking.estimatedPrice;
    final isFinal = booking.finalPrice != null;
    final currency = booking.currency ?? 'EGP';
    final needsAction = booking.status == BookingStatus.waitingForUserAction;
    final isPast = _isPast(booking.status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Trip to $destination',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BrandTokens.heading(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: BrandTokens.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BookingStatusChip(status: booking.status, dense: true),
            ],
          ),
          const SizedBox(height: 8),

          // Date · duration · type
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                DateFormat('MMM d, yyyy')
                    .format(booking.requestedDate.toLocal()),
                style: BrandTokens.body(
                    fontSize: 12, color: BrandTokens.textSecondary),
              ),
              _dot,
              Text(
                _dur(booking.durationInMinutes),
                style: BrandTokens.body(
                    fontSize: 12, color: BrandTokens.textSecondary),
              ),
              _dot,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    booking.type == BookingType.scheduled
                        ? Icons.calendar_month_outlined
                        : Icons.bolt_rounded,
                    size: 13,
                    color: BrandTokens.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    booking.type == BookingType.scheduled
                        ? 'Scheduled'
                        : 'Instant',
                    style: BrandTokens.body(
                        fontSize: 12, color: BrandTokens.textSecondary),
                  ),
                ],
              ),
            ],
          ),

          // Helper name
          if (booking.helper != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 13, color: BrandTokens.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.helper!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BrandTokens.body(
                        fontSize: 12, color: BrandTokens.textSecondary),
                  ),
                ),
              ],
            ),
          ],

          // Action-needed alert
          if (needsAction) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: BrandTokens.warningAmber.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: BrandTokens.warningAmber.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: BrandTokens.warningAmber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This trip requires your attention.',
                      style: BrandTokens.body(
                          fontSize: 12, color: BrandTokens.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          Container(height: 1, color: BrandTokens.borderSoft),
          const SizedBox(height: 12),

          // Price + CTA
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL PRICE',
                    style: BrandTokens.heading(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: BrandTokens.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price != null
                        ? '${isFinal ? '' : '~​'}${price.toStringAsFixed(0)} $currency'
                        : '--',
                    style: BrandTokens.numeric(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: BrandTokens.textPrimary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _CtaButton(booking: booking, isPast: isPast),
            ],
          ),
        ],
      ),
    );
  }

  static String _dur(int m) {
    if (m <= 0) return '--';
    if (m < 60) return '${m}m';
    if (m % 60 == 0) return '${m ~/ 60}h';
    return '${m ~/ 60}h ${m % 60}m';
  }

  static const _dot = _Dot();
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => Container(
        width: 3,
        height: 3,
        decoration: const BoxDecoration(
          color: BrandTokens.textMuted,
          shape: BoxShape.circle,
        ),
      );
}

class _CtaButton extends StatelessWidget {
  final BookingDetailEntity booking;
  final bool isPast;
  const _CtaButton({required this.booking, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final needsAction = booking.status == BookingStatus.waitingForUserAction;
    final isLive = booking.status == BookingStatus.inProgress;

    final bg = needsAction
        ? BrandTokens.warningAmber
        : isPast
            ? BrandTokens.borderSoft
            : BrandTokens.primaryBlue.withValues(alpha: 0.10);

    final fg = needsAction
        ? Colors.white
        : isPast
            ? BrandTokens.textSecondary
            : BrandTokens.primaryBlue;

    final label = needsAction
        ? 'Take Action'
        : isLive
            ? 'Open Trip'
            : isPast
                ? 'View Details'
                : 'View Details';

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.pushNamed(
          'booking-details',
          pathParameters: {'id': booking.id},
          extra: {'booking': booking},
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          label,
          style: BrandTokens.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _Filter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (filter) {
      _Filter.active => (
          Icons.explore_outlined,
          'No active trips',
          'Start a booking to see your in-flight trips here.',
        ),
      _Filter.upcoming => (
          Icons.calendar_today_outlined,
          'No upcoming trips',
          'Confirmed future journeys will appear here.',
        ),
      _Filter.past => (
          Icons.history_rounded,
          'No past trips',
          'Your completed adventures will be archived here.',
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: BrandTokens.primaryBlue, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: BrandTokens.heading(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BrandTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: BrandTokens.body(
                  fontSize: 13, color: BrandTokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: BrandTokens.dangerSos),
            const SizedBox(height: 12),
            Text(
              'Could not load trips',
              style: BrandTokens.heading(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BrandTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: BrandTokens.body(
                  fontSize: 13, color: BrandTokens.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandTokens.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE7EAF6),
      highlightColor: const Color(0xFFF6F8FE),
      period: const Duration(milliseconds: 1400),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        children: [
          // Headline skeleton
          Container(
            width: 160,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 18),
          // Filter chips skeleton
          Row(
            children: [
              for (final w in [80.0, 95.0, 70.0])
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    width: w,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Card skeletons
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                height: 290,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
