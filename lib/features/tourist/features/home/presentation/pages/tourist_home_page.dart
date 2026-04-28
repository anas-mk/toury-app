import 'dart:ui' as ui;

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

/// RAFIQ tourist home — Pass #5 redesign.
///
/// Design intent
/// -------------
/// 2026 fintech / travel feel. The shell is a single CustomScrollView
/// because nested scrolling kills perceived speed; everything below the
/// hero lives in one SliverList that streams in.
///
///   1. Animated mesh hero with organic blob bottom edge.
///      A glass weather-style "live status" chip floats over the mesh.
///   2. Bento grid (2 cols x 2 rows). Big amber Instant tile spans 2
///      cols on top; below it three small tiles: Scheduled, My trips,
///      Wallet teaser.
///   3. Active trip "live" card (only when there's an active booking)
///      with a PulseDot + ETA-style chip. Tap = open booking details.
///   4. Recent trips horizontal carousel (snap, peek next item).
///   5. Pull-to-refresh and shimmer skeletons everywhere.
///
/// Performance
/// -----------
/// * The mesh hero is the only animated subtree on the home page; it
///   is wrapped in a RepaintBoundary so paint cost does not bleed into
///   the rest of the screen.
/// * Every list/grid item is `const` where possible so widget rebuilds
///   are cheap when bloc states change.
/// * `BlocBuilder.buildWhen` keeps the active-trip card from rebuilding
///   when only the recent-list state churns.
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
      // Lazy first load. If the cubit was just created (Initial state)
      // we kick a fetch; otherwise we keep the cached data and let the
      // user pull-to-refresh manually. This stops the home page from
      // hammering /api/user/bookings every time the user comes back to
      // the home tab from another tab.
      final statusCubit = context.read<BookingStatusCubit>();
      if (statusCubit.state is BookingStatusInitial) {
        statusCubit.startPollingForActive();
      }
      final myBookings = context.read<MyBookingsCubit>();
      if (myBookings.state is MyBookingsInitial) {
        myBookings.getBookings(pageSize: 5);
      }
      // Phase 3: register both home cubits with the app-wide realtime
      // orchestrator so trip-status / cancellation / trip-end events
      // refresh the home screen automatically.
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
    final greeting = _greetingForNow();
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
                greeting: greeting,
                onAvatarTap: () => context.go('/account-settings'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  // ── Bento grid ───────────────────────────────────
                  _BentoGrid(
                    onInstant: () =>
                        context.push(AppRouter.instantTripDetails),
                    onScheduled: () =>
                        context.push(AppRouter.scheduledSearch),
                    onMyTrips: () => context.go(AppRouter.myBookings),
                    onWallet: () => context.go('/account-settings'),
                  ),
                  const SizedBox(height: 22),

                  // ── Active trip live card ────────────────────────
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

                  // ── Recent trips header ──────────────────────────
                  _RecentTripsHeader(
                    onSeeAll: () => context.go(AppRouter.myBookings),
                  ),
                  const SizedBox(height: 12),

                  // ── Recent trips carousel ────────────────────────
                  BlocBuilder<MyBookingsCubit, MyBookingsState>(
                    builder: (context, state) {
                      if (state is MyBookingsLoading ||
                          state is MyBookingsInitial) {
                        return const _RecentTripsSkeleton();
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
                        return _RecentTripsCarousel(
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
                  const _TrustStrip(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greetingForNow() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ============================================================================
//  HERO  (animated mesh + organic blob bottom)
// ============================================================================

class _HomeHero extends StatelessWidget {
  final String? firstName;
  final String greeting;
  final VoidCallback onAvatarTap;

  const _HomeHero({
    required this.firstName,
    required this.greeting,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final mediaTop = MediaQuery.of(context).padding.top;
    final initial =
        (firstName != null && firstName!.isNotEmpty) ? firstName![0] : 'T';
    return ClipPath(
      clipper: const _HomeHeroBlobClipper(),
      child: SizedBox(
        height: 268 + mediaTop,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const RepaintBoundary(child: MeshGradientBackground()),
            // Bottom dim so headline reads against bright mesh blobs.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x140F1655),
                    Color(0x4D0F1655),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                mediaTop + 14,
                20,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wordmark + glass live chip + avatar
                  Row(
                    children: [
                      Text(
                        BrandTokens.wordmark,
                        style: BrandTokens.wordmarkStyle(fontSize: 24),
                      ),
                      const Spacer(),
                      const _HeroLiveChip(),
                      const SizedBox(width: 10),
                      _HeroAvatar(
                        initial: initial,
                        onTap: onAvatarTap,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    greeting,
                    style: BrandTokens.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    firstName == null || firstName!.isEmpty
                        ? 'Hi, traveler'
                        : 'Hi, $firstName',
                    style: BrandTokens.heading(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Where to today?',
                    style: BrandTokens.body(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeroBlobClipper extends CustomClipper<Path> {
  const _HomeHeroBlobClipper();

  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 36);
    p.cubicTo(
      size.width * 0.25, size.height - 4,
      size.width * 0.55, size.height - 64,
      size.width * 0.78, size.height - 30,
    );
    p.cubicTo(
      size.width * 0.92, size.height - 14,
      size.width, size.height - 38,
      size.width, size.height - 60,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HeroAvatar extends StatelessWidget {
  final String initial;
  final VoidCallback onTap;

  const _HeroAvatar({required this.initial, required this.onTap});

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
          color: Colors.white.withValues(alpha: 0.22),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1.4,
          ),
        ),
        child: Text(
          initial.toUpperCase(),
          style: BrandTokens.heading(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Frosted "weather widget" pill floating in the hero.
class _HeroLiveChip extends StatelessWidget {
  const _HeroLiveChip();

  @override
  Widget build(BuildContext context) {
    // Pass #5 perf: BackdropFilter over an animated subtree (the mesh)
    // is one of the most expensive operations in Flutter. We keep it
    // small (sigma 6 instead of 12) and wrap the result in a
    // RepaintBoundary so the filter result is cached and doesn't
    // re-blur every time the mesh advances a frame.
    return RepaintBoundary(
      child: ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.32),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The PulseDot widget paints rings up to size*3.6, but here we
              // only want a small static dot in the chip. Use a plain green
              // circle to avoid clipping the pulse rings inside the pill.
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: BrandTokens.successGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: BrandTokens.successGreen,
                      blurRadius: 6,
                      spreadRadius: -1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Helpers online',
                style: BrandTokens.body(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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

// ============================================================================
//  BENTO GRID
// ============================================================================

class _BentoGrid extends StatelessWidget {
  final VoidCallback onInstant;
  final VoidCallback onScheduled;
  final VoidCallback onMyTrips;
  final VoidCallback onWallet;

  const _BentoGrid({
    required this.onInstant,
    required this.onScheduled,
    required this.onMyTrips,
    required this.onWallet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BentoInstantTile(onTap: onInstant),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _BentoSmallTile(
                title: 'Scheduled',
                subtitle: 'Plan a trip',
                icon: Icons.event_available_rounded,
                accent: BrandTokens.primaryBlue,
                onTap: onScheduled,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: BlocBuilder<MyBookingsCubit, MyBookingsState>(
                buildWhen: (a, b) => a.runtimeType != b.runtimeType ||
                    (a is MyBookingsLoaded &&
                        b is MyBookingsLoaded &&
                        a.bookings.length != b.bookings.length),
                builder: (context, state) {
                  final count = state is MyBookingsLoaded
                      ? state.bookings.length
                      : null;
                  return _BentoSmallTile(
                    title: 'My trips',
                    subtitle: count == null
                        ? 'View history'
                        : '$count ${count == 1 ? 'trip' : 'trips'}',
                    icon: Icons.luggage_rounded,
                    accent: const Color(0xFF6B5BFF),
                    badge: count != null && count > 0
                        ? '$count'
                        : null,
                    onTap: onMyTrips,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _BentoWalletTile(onTap: onWallet),
      ],
    );
  }
}

// Big amber tile — primary CTA. Spring-press, pulse dot, parallax arrow.
class _BentoInstantTile extends StatefulWidget {
  final VoidCallback onTap;
  const _BentoInstantTile({required this.onTap});

  @override
  State<_BentoInstantTile> createState() => _BentoInstantTileState();
}

class _BentoInstantTileState extends State<_BentoInstantTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'instant-cta',
      child: Material(
        color: Colors.transparent,
        child: AnimatedScale(
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
            child: _build(),
          ),
        ),
      ),
    );
  }

  Widget _build() {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        gradient: BrandTokens.amberGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: BrandTokens.ctaAmberGlow,
      ),
      child: Stack(
        children: [
          // Decorative blob in the corner.
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -50,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Text(
                          'INSTANT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Book a helper now',
                        style: BrandTokens.heading(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'On-demand, responds in minutes',
                        style: BrandTokens.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: BrandTokens.accentAmber,
                    size: 20,
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

class _BentoSmallTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String? badge;
  final VoidCallback onTap;

  const _BentoSmallTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  @override
  State<_BentoSmallTile> createState() => _BentoSmallTileState();
}

class _BentoSmallTileState extends State<_BentoSmallTile> {
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
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: Container(
          height: 132,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: BrandTokens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.accent, size: 20),
                  ),
                  const Spacer(),
                  if (widget.badge != null)
                    Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      height: 22,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: widget.accent,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        widget.badge!,
                        style: BrandTokens.heading(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                widget.title,
                style: BrandTokens.heading(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: BrandTokens.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: BrandTokens.body(
                  fontSize: 12,
                  color: BrandTokens.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoWalletTile extends StatelessWidget {
  final VoidCallback onTap;
  const _BentoWalletTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 96,
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        decoration: BoxDecoration(
          gradient: BrandTokens.primaryGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: BrandTokens.ctaBlueGlow,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Account',
                        style: BrandTokens.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Settings & support',
                        style: BrandTokens.heading(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
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
                  // PulseDot paints up to size*3.6 — give it room so the
                  // outer rings don't clip on the live trip card header.
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
                      booking.helper?.name ?? 'Awaiting helper',
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
//  RECENT TRIPS  (header + carousel)
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

class _RecentTripsCarousel extends StatelessWidget {
  final List<BookingDetailEntity> bookings;
  final ValueChanged<BookingDetailEntity> onTapBooking;

  const _RecentTripsCarousel({
    required this.bookings,
    required this.onTapBooking,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 184,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: bookings.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _RecentTripCard(
          booking: bookings[i],
          onTap: () => onTapBooking(bookings[i]),
        ),
      ),
    );
  }
}

class _RecentTripCard extends StatelessWidget {
  final BookingDetailEntity booking;
  final VoidCallback onTap;

  const _RecentTripCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final destination = booking.destinationName ?? booking.destinationCity;
    final formatted = DateFormat('MMM d').format(booking.requestedDate.toLocal());
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: BrandTokens.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: BrandTokens.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: booking.helper?.profileImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                booking.helper!.profileImageUrl!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                    ),
                    const Spacer(),
                    BookingStatusChip(status: booking.status, dense: true),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  destination,
                  style: BrandTokens.heading(
                    fontSize: 15,
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
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: BrandTokens.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatted,
                      style: BrandTokens.body(
                        fontSize: 12,
                        color: BrandTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (booking.finalPrice != null)
                  Text(
                    '${booking.finalPrice!.toStringAsFixed(0)} ${booking.currency ?? 'EGP'}',
                    style: BrandTokens.numeric(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: BrandTokens.accentAmberText,
                    ),
                  )
                else if (booking.estimatedPrice != null)
                  Text(
                    '~ ${booking.estimatedPrice!.toStringAsFixed(0)} ${booking.currency ?? 'EGP'}',
                    style: BrandTokens.numeric(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BrandTokens.textSecondary,
                    ),
                  )
                else
                  Text(
                    'Estimate pending',
                    style: BrandTokens.body(
                      fontSize: 12,
                      color: BrandTokens.textSecondary,
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

class _RecentTripsSkeleton extends StatelessWidget {
  const _RecentTripsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 184,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
          width: 220,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: BrandTokens.cardShadow,
          ),
          child: const SkeletonShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonBlock(width: 36, height: 36, radius: 18),
                    Spacer(),
                    SkeletonBlock(width: 56, height: 18, radius: 10),
                  ],
                ),
                SizedBox(height: 14),
                SkeletonBlock(width: 140, height: 14),
                SizedBox(height: 6),
                SkeletonBlock(width: 80, height: 10),
                Spacer(),
                SkeletonBlock(width: 90, height: 16),
              ],
            ),
          ),
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
            'Book your first helper and start exploring.',
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
                'Book a helper now',
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

// ============================================================================
//  TRUST STRIP (footer)
// ============================================================================

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    const items = [
      _TrustItem(
        icon: Icons.verified_user_rounded,
        title: 'Verified',
        subtitle: 'Helpers',
        color: BrandTokens.accentAmber,
      ),
      _TrustItem(
        icon: Icons.location_on_rounded,
        title: 'Live',
        subtitle: 'Tracking',
        color: BrandTokens.primaryBlue,
      ),
      _TrustItem(
        icon: Icons.public_rounded,
        title: 'Local',
        subtitle: 'Expertise',
        color: BrandTokens.successGreen,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _TrustChip(data: items[i])),
          if (i != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _TrustItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _TrustItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _TrustChip extends StatelessWidget {
  final _TrustItem data;
  const _TrustChip({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            data.title,
            style: BrandTokens.heading(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: BrandTokens.textPrimary,
            ),
          ),
          Text(
            data.subtitle,
            style: BrandTokens.body(
              fontSize: 11,
              color: BrandTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
