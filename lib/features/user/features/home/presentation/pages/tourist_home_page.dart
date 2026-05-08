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
import '../../../../../../core/widgets/user_avatar.dart';
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
      // Warm cream background from the new design (#FAF8F4) — matches
      // the cream surface the action card + chips sit on.
      backgroundColor: const Color(0xFFFAF8F4),
      body: RefreshIndicator.adaptive(
        onRefresh: _refresh,
        color: BrandTokens.primaryBlue,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── Hero + overlapping action card (in a single Stack) ─
            SliverToBoxAdapter(
              child: _HomeHeroSection(
                firstName: _firstName,
                onInstant: () => context.push(AppRouter.instantTripDetails),
                onScheduled: () => context.push(AppRouter.scheduledSearch),
              ),
            ),

            // ── Active trip + Recent trips ────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
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

                  _RecentTripsHeader(
                    onSeeAll: () => context.go(AppRouter.myBookings),
                  ),
                  const SizedBox(height: 12),

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
//  HERO SECTION (image + greeting + overlapping action card)
// ============================================================================

/// Combines the cinematic hero image and the search/CTA action card in a
/// single stack so the action card can genuinely overlap the bottom of
/// the hero (vs. `Transform.translate`, which leaves a layout gap and
/// pushes content below it down by the hero's full height).
class _HomeHeroSection extends StatelessWidget {
  final String? firstName;
  final VoidCallback onInstant;
  final VoidCallback onScheduled;

  const _HomeHeroSection({
    required this.firstName,
    required this.onInstant,
    required this.onScheduled,
  });

  @override
  Widget build(BuildContext context) {
    final mediaTop = MediaQuery.of(context).padding.top;

    // Hero height matches the reference design (486 px) plus the
    // status bar so the gradient fully covers the notch area.
    const double heroVisualHeight = 486.0;
    final double heroHeight = heroVisualHeight + mediaTop;

    // Action card sits BELOW the hero with only a small overlap, like
    // the reference's `-mt-8` (32 px). Most of the card is on the
    // cream background, which keeps the search bar fully legible and
    // gives the greeting room to breathe in the lower half of the
    // hero (matching the design).
    const double cardOverlap = 32.0;

    return SizedBox(
      // Total section height: hero + the action card height that
      // protrudes below the hero. We can't measure the card
      // dynamically, so estimate generously: search 56 + gap 14 +
      // cta 56 + gap 14 + link 28 + breathing 8 = 176 px protruding
      // (i.e. card height ~176 - cardOverlap that's hidden by hero).
      height: heroHeight + 176 - cardOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Hero image + gradient + top bar + greeting.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _HomeHero(firstName: firstName, height: heroHeight),
          ),

          // Action card overlapping the bottom of the hero by 32 px.
          Positioned(
            top: heroHeight - cardOverlap,
            left: 20,
            right: 20,
            child: _ActionCard(
              onInstant: onInstant,
              onScheduled: onScheduled,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  final String? firstName;
  final double height;

  const _HomeHero({required this.firstName, required this.height});

  @override
  Widget build(BuildContext context) {
    final mediaTop = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: height,
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

          // ── Gradient: dark at the very top for top-bar legibility,
          //    deep enough mid-frame for the greeting, fades to the
          //    warm cream `bgSoft` at the seam where the action card
          //    starts overlapping.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.45, 0.85, 1.0],
                colors: [
                  Color(0x1A000000), // 10% black – legibility for top bar
                  Color(0x66000000), // 40% black – greeting readability
                  Color(0xCCFAF8F4), // cream haze before the seam
                  Color(0xFFFAF8F4), // solid cream — meets scaffold bg
                ],
              ),
            ),
          ),

          // ── Top bar: menu + RAFIQ on left, avatar on right ──────
          Positioned(
            top: mediaTop + 12,
            left: 16,
            right: 16,
            child: _HomeTopBar(
              onMenu: () => context.goNamed('account-settings'),
              onAvatar: () => context.goNamed('account-settings'),
            ),
          ),

          // ── Greeting text — sits in the lower portion of the hero
          //    (matches `bottom-16` ≈ 64 px in the reference). The
          //    action card overlaps only the last 32 px of the hero,
          //    so the greeting stays well clear above it.
          Positioned(
            left: 24,
            right: 24,
            bottom: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Where to today,',
                  style: BrandTokens.body(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName == null || firstName!.isEmpty
                      ? 'Traveler?'
                      : '$firstName?',
                  style: BrandTokens.heading(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
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

// ============================================================================
//  TOP BAR (menu + RAFIQ wordmark on left, user avatar on right)
// ============================================================================

class _HomeTopBar extends StatelessWidget {
  final VoidCallback onMenu;
  final VoidCallback onAvatar;

  const _HomeTopBar({required this.onMenu, required this.onAvatar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeroIconButton(icon: Icons.menu_rounded, onTap: onMenu),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(
            text: 'RAFIQ',
            style: TextStyle(
              inherit: false,
              fontFamily: 'PermanentMarker',
              fontSize: 24,
              color: Colors.white,
              shadows: [
                Shadow(color: Color(0x66000000), blurRadius: 8),
              ],
            ),
          ),
        ),
        const Spacer(),
        UserAvatar(
          size: 36,
          fontSize: 13,
          backgroundColor: Colors.white.withValues(alpha: 0.18),
          foregroundColor: Colors.white,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
          onTap: () {
            HapticFeedback.selectionClick();
            onAvatar();
          },
        ),
      ],
    );
  }
}

// ============================================================================
//  ACTION CARD — search bar + Find a Guide CTA + Schedule for later link
// ============================================================================

class _ActionCard extends StatelessWidget {
  final VoidCallback onInstant;
  final VoidCallback onScheduled;

  const _ActionCard({required this.onInstant, required this.onScheduled});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pill-style search bar (height 56, radius 28).
        const _HeroSearchBar(),
        const SizedBox(height: 14),
        Hero(
          tag: 'instant-cta',
          child: _FindGuideButton(onTap: onInstant),
        ),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              onScheduled();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              child: Text(
                'Schedule for later →',
                style: BrandTokens.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BrandTokens.primaryBlue,
                ).copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor:
                      BrandTokens.primaryBlue.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSearchBar extends StatelessWidget {
  const _HeroSearchBar();

  @override
  Widget build(BuildContext context) {
    // Pill search bar — sits on the cream background, soft border to
    // feel airy (matches the new mock).
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: BrandTokens.borderSoft.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Icon(
            Icons.search_rounded,
            color: BrandTokens.primaryBlue.withValues(alpha: 0.85),
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
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: BrandTokens.primaryBlue,
              size: 20,
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
            color: BrandTokens.primaryBlue,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Find a Guide Now',
                style: BrandTokens.heading(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
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
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: BrandTokens.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onSeeAll();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'View all →',
              style: BrandTokens.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: BrandTokens.primaryBlue,
              ),
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
          border: Border.all(
            color: BrandTokens.borderSoft.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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

