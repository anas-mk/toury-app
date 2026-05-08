import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../../../../core/services/realtime/app_realtime_cubit.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/utils/jwt_payload.dart';
import '../../../../../../core/widgets/booking_status_chip.dart';
import '../../../../../../core/widgets/brand/brand_kit.dart';
import '../../../user_booking/domain/entities/booking_detail_entity.dart';
import '../../../user_booking/presentation/cubits/booking_status_cubit.dart';
import '../../../user_booking/presentation/cubits/booking_status_state.dart';
import '../../../user_booking/presentation/cubits/my_bookings_cubit.dart';
import '../../../user_booking/presentation/cubits/my_bookings_state.dart';

class TouristHomePage extends StatefulWidget {
  const TouristHomePage({super.key});

  @override
  State<TouristHomePage> createState() => _TouristHomePageState();
}

class _TouristHomePageState extends State<TouristHomePage> {
  String? _firstName;
  BookingStatusCubit? _registeredStatusCubit;
  MyBookingsCubit? _registeredMyBookings;

  @override
  void initState() {
    super.initState();
    _firstName = _resolveFirstName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final statusCubit = context.read<BookingStatusCubit>();
      if (statusCubit.state is BookingStatusInitial) {
        statusCubit.startPollingForActive();
      }
      final myBookings = context.read<MyBookingsCubit>();
      if (myBookings.state is MyBookingsInitial) {
        myBookings.getBookings(pageSize: 5);
      }
      final rt = sl<AppRealtimeCubit>();
      rt.registerBookingStatus(statusCubit);
      rt.registerMyBookings(myBookings);
      _registeredStatusCubit = statusCubit;
      _registeredMyBookings = myBookings;
    });
  }

  @override
  void dispose() {
    final rt = sl<AppRealtimeCubit>();
    final s = _registeredStatusCubit;
    if (s != null) rt.unregisterBookingStatus(s);
    final m = _registeredMyBookings;
    if (m != null) rt.unregisterMyBookings(m);
    super.dispose();
  }

  String? _resolveFirstName() {
    try {
      final token = sl<AuthService>().getToken();
      final name = JwtPayload.firstName(token);
      if (name == null || name.isEmpty) return null;
      return name[0].toUpperCase() + name.substring(1);
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<BookingStatusCubit>().startPollingForActive(),
      context.read<MyBookingsCubit>().refreshBookings(pageSize: 5),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandTokens.bgSoft,
      body: RefreshIndicator.adaptive(
        onRefresh: _refresh,
        color: BrandTokens.primaryBlue,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHero(
                firstName: _firstName,
                onInstant: () => context.push(AppRouter.instantTripDetails),
                onScheduled: () => context.push(AppRouter.scheduledSearch),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  // ── Active trip live card ─────────────────────────
                  BlocBuilder<BookingStatusCubit, BookingStatusState>(
                    buildWhen: (a, b) => a.runtimeType != b.runtimeType ||
                        (a is BookingStatusActive &&
                            b is BookingStatusActive &&
                            a.booking.id != b.booking.id),
                    builder: (context, state) {
                      if (state is BookingStatusActive) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: _LiveTripCard(
                            booking: state.booking,
                            onTap: () => context.pushNamed(
                              'booking-details',
                              pathParameters: {'id': state.booking.id},
                              extra: {'booking': state.booking},
                            ),
                          ),
                        );
                      }
                      if (state is BookingStatusLoading) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 22),
                          child: _LiveTripSkeleton(),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // ── Recent trips header ───────────────────────────
                  _RecentTripsHeader(
                    onSeeAll: () => context.go(AppRouter.myBookings),
                  ),
                  const SizedBox(height: 12),

                  // ── Recent trips pills ────────────────────────────
                  BlocBuilder<MyBookingsCubit, MyBookingsState>(
                    builder: (context, state) {
                      if (state is MyBookingsLoading ||
                          state is MyBookingsInitial) {
                        return const _RecentTripsPillsSkeleton();
                      }
                      if (state is MyBookingsError) {
                        return _ErrorTile(
                          message: state.message,
                          onRetry: () => context
                              .read<MyBookingsCubit>()
                              .refreshBookings(pageSize: 5),
                        );
                      }
                      if (state is MyBookingsLoaded) {
                        final recent = state.bookings.take(5).toList();
                        if (recent.isEmpty) {
                          return _EmptyTripsCard(
                            onTap: () =>
                                context.push(AppRouter.instantTripDetails),
                          );
                        }
                        return _RecentTripsPills(
                          bookings: recent,
                          onTapBooking: (b) => context.pushNamed(
                            'booking-details',
                            pathParameters: {'id': b.id},
                            extra: {'booking': b},
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 28),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
//  HERO
// ============================================================================

class _HomeHero extends StatelessWidget {
  final String? firstName;
  final VoidCallback onInstant;
  final VoidCallback onScheduled;

  const _HomeHero({
    required this.firstName,
    required this.onInstant,
    required this.onScheduled,
  });

  @override
  Widget build(BuildContext context) {
    final mediaTop = MediaQuery.of(context).padding.top;

    // ~67% of a standard 844 logical-px screen, matching Ahmed proportions.
    const double heroContentHeight = 520.0;
    final double heroHeight = heroContentHeight + mediaTop;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background photo ─────────────────────────────────────
          Image.asset(
            'assets/images/hero_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const RepaintBoundary(child: MeshGradientBackground()),
          ),

          // ── Gradient: top 25% fully clear (image breathes like Ahmed),
          //    then ramps to dark just before the greeting text zone.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.25, 0.36, 0.54, 0.72, 1.0],
                colors: [
                  Color(0x00000000), // 0%  – fully transparent at top
                  Color(0x00000000), // 0%  – still clear through top quarter
                  Color(0x66000000), // 40% – ramps dark just before greeting
                  Color(0x99000000), // 60% – darkest: name text readability
                  Color(0x80000000), // 50% – search + CTA zone
                  Color(0x66000000), // 40% – schedule link at bottom
                ],
              ),
            ),
          ),

          // ── Content column ───────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(24, mediaTop + 16, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar: hamburger + RAFIQ on the LEFT (matching reference)
                Row(
                  children: [
                    _HeroIconButton(
                      icon: Icons.menu_rounded,
                      onTap: () {},
                    ),
                    const SizedBox(width: 12),
                    RichText(
                      text: const TextSpan(
                        text: 'RAFIQ',
                        style: TextStyle(
                          inherit: false,
                          fontFamily: 'PermanentMarker',
                          fontSize: 32,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Color(0x66000000),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Single spacer pushes ALL content to bottom of hero
                const Spacer(),

                // "Where to today," – 18px light
                Text(
                  'Where to today,',
                  style: BrandTokens.body(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 4),

                // User name – 48px bold
                Text(
                  firstName == null || firstName!.isEmpty
                      ? 'Traveler?'
                      : '$firstName?',
                  style: BrandTokens.heading(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 20),

                // Search bar – height 64, radius 32
                const _HeroSearchBar(),
                const SizedBox(height: 12),

                // Find a Guide Now – height 56, radius 12
                Hero(
                  tag: 'instant-cta',
                  child: _FindGuideButton(onTap: onInstant),
                ),
                const SizedBox(height: 12),

                // Schedule for later
                Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onScheduled();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Schedule for later →',
                        style: BrandTokens.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
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

class _HeroSearchBar extends StatelessWidget {
  const _HeroSearchBar();

  @override
  Widget build(BuildContext context) {
    // Spec: height 64px, border-radius 32px, light shadow
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          const Icon(
            Icons.search_rounded,
            color: BrandTokens.textMuted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search destinations, landmarks…',
              style: BrandTokens.body(
                fontSize: 14,
                color: BrandTokens.textMuted,
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(
              color: BrandTokens.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _FindGuideButton extends StatefulWidget {
  final VoidCallback onTap;
  const _FindGuideButton({required this.onTap});

  @override
  State<_FindGuideButton> createState() => _FindGuideButtonState();
}

class _FindGuideButtonState extends State<_FindGuideButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: BrandTokens.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: BrandTokens.ctaBlueGlow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'Find a Guide Now',
                style: BrandTokens.heading(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ============================================================================
//  ACTIVE TRIP "live" CARD
// ============================================================================

class _LiveTripCard extends StatelessWidget {
  final BookingDetailEntity booking;
  final VoidCallback onTap;

  const _LiveTripCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final destination = booking.destinationName ?? booking.destinationCity;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: BrandTokens.cardShadow,
            border: Border.all(
              color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: RepaintBoundary(
                        child: PulseDot(size: 9, rings: 2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'YOUR ACTIVE TRIP',
                    style: BrandTokens.heading(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: BrandTokens.primaryBlue,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const Spacer(),
                  BookingStatusChip(status: booking.status, dense: true),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Trip to $destination',
                style: BrandTokens.heading(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: BrandTokens.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: BrandTokens.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.helper?.name ?? 'Awaiting guide',
                      style: BrandTokens.body(
                        fontSize: 13,
                        color: BrandTokens.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: BrandTokens.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Open trip',
                      style: BrandTokens.heading(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveTripSkeleton extends StatelessWidget {
  const _LiveTripSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: BrandTokens.cardShadow,
      ),
      child: const SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(width: 160, height: 12),
            SizedBox(height: 14),
            SkeletonBlock(width: 220, height: 18),
            SizedBox(height: 8),
            SkeletonBlock(width: 140, height: 12),
            SizedBox(height: 16),
            SkeletonBlock(width: double.infinity, height: 44),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
//  RECENT TRIPS  (header + pill chips)
// ============================================================================

class _RecentTripsHeader extends StatelessWidget {
  final VoidCallback onSeeAll;
  const _RecentTripsHeader({required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Recent trips',
            style: BrandTokens.heading(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: BrandTokens.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSeeAll();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: BrandTokens.accentAmberSoft,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              children: [
                Text(
                  'See all',
                  style: BrandTokens.heading(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: BrandTokens.accentAmberText,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: BrandTokens.accentAmberText,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentTripsPills extends StatelessWidget {
  final List<BookingDetailEntity> bookings;
  final ValueChanged<BookingDetailEntity> onTapBooking;

  const _RecentTripsPills({
    required this.bookings,
    required this.onTapBooking,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: bookings.length,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _TripPill(
          booking: bookings[i],
          onTap: () => onTapBooking(bookings[i]),
        ),
      ),
    );
  }
}

class _TripPill extends StatelessWidget {
  final BookingDetailEntity booking;
  final VoidCallback onTap;

  const _TripPill({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final destination = booking.destinationName ?? booking.destinationCity;
    final formatted =
        DateFormat('MMM d').format(booking.requestedDate.toLocal());

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: BrandTokens.cardShadow,
          border: Border.all(color: BrandTokens.borderSoft),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              destination,
              style: BrandTokens.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: BrandTokens.textPrimary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: BrandTokens.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Text(
              formatted,
              style: BrandTokens.body(
                fontSize: 13,
                color: BrandTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTripsPillsSkeleton extends StatelessWidget {
  const _RecentTripsPillsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => const SkeletonShimmer(
          child: SkeletonBlock(width: 130, height: 44, radius: 40),
        ),
      ),
    );
  }
}

// ============================================================================
//  EMPTY / ERROR
// ============================================================================

class _EmptyTripsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyTripsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: BrandTokens.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: BrandTokens.amberGradient,
              shape: BoxShape.circle,
              boxShadow: BrandTokens.ctaAmberGlow,
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No trips yet',
            style: BrandTokens.heading(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: BrandTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Book your first guide and start exploring.',
            textAlign: TextAlign.center,
            style: BrandTokens.body(
              fontSize: 13,
              color: BrandTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandTokens.accentAmber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.bolt_rounded),
              label: Text(
                'Find a Guide Now',
                style: BrandTokens.heading(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorTile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandTokens.dangerRedSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrandTokens.dangerRed.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: BrandTokens.dangerRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not load trips: $message',
              style: BrandTokens.body(
                fontSize: 12,
                color: BrandTokens.dangerRed,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: BrandTokens.heading(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: BrandTokens.dangerRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

