import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/jwt_payload.dart';
import '../../../../../../core/widgets/booking_status_chip.dart';
import '../../../../../../core/widgets/hero_header.dart';
import '../../../user_booking/domain/entities/booking_detail_entity.dart';
import '../../../user_booking/presentation/cubits/booking_status_cubit.dart';
import '../../../user_booking/presentation/cubits/booking_status_state.dart';
import '../../../user_booking/presentation/cubits/my_bookings_cubit.dart';
import '../../../user_booking/presentation/cubits/my_bookings_state.dart';

/// Premium tourism home page (Pass #2).
///
/// Layout:
///   1. Hero band with brand gradient, greeting, value prop, avatar.
///   2. Big primary CTA: "Book a helper now" (Instant).
///   3. Secondary card: "Plan ahead" (Scheduled).
///   4. "Why RAFIQ" trust strip (3 chips).
///   5. Conditional "Your active trip" section.
///   6. "Recent trips" horizontal carousel (last 3).
///   7. Pull-to-refresh and shimmer skeletons.
class TouristHomePage extends StatefulWidget {
  const TouristHomePage({super.key});

  @override
  State<TouristHomePage> createState() => _TouristHomePageState();
}

class _TouristHomePageState extends State<TouristHomePage> {
  String? _firstName;

  @override
  void initState() {
    super.initState();
    _firstName = _resolveFirstName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BookingStatusCubit>().startPollingForActive();
      context.read<MyBookingsCubit>().refreshBookings(pageSize: 5);
    });
  }

  /// Read the user's first name from the JWT we already have in
  /// SharedPreferences. We don't fetch /profile here because:
  ///   - the user may be offline,
  ///   - we do NOT want to gate the home render on a network call.
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
    final theme = Theme.of(context);
    final greeting = _greetingForNow();
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColor.accentColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHero(
                firstName: _firstName,
                greeting: greeting,
                onAvatarTap: () => context.go('/account-settings'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLG,
                AppTheme.spaceLG,
                AppTheme.spaceLG,
                AppTheme.space2XL,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _PrimaryInstantCta(
                    onTap: () => context.push(AppRouter.instantTripDetails),
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  _SecondaryScheduledCta(
                    onTap: () => context.push(AppRouter.scheduledSearch),
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                  const _WhyRafiqStrip(),
                  const SizedBox(height: AppTheme.spaceLG),
                  BlocBuilder<BookingStatusCubit, BookingStatusState>(
                    builder: (context, state) {
                      if (state is BookingStatusActive) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppTheme.spaceLG),
                          child: _ActiveTripCard(
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
                          padding:
                              EdgeInsets.only(bottom: AppTheme.spaceLG),
                          child: _ActiveTripSkeleton(),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(child: SectionTitle('Recent trips')),
                      TextButton(
                        onPressed: () => context.go(AppRouter.myBookings),
                        child: Text(
                          'View all',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColor.secondaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
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
                        final recent = state.bookings.take(3).toList();
                        if (recent.isEmpty) {
                          return _EmptyTripsCard(
                            onTap: () =>
                                context.push(AppRouter.instantTripDetails),
                          );
                        }
                        return SizedBox(
                          height: 196,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: recent.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: AppTheme.spaceMD),
                            itemBuilder: (_, i) => _RecentTripCard(
                              booking: recent[i],
                              onTap: () => context.pushNamed(
                                'booking-details',
                                pathParameters: {'id': recent[i].id},
                                extra: {'booking': recent[i]},
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
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
// Hero band
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
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spaceLG,
        mediaTop + AppTheme.spaceMD,
        AppTheme.spaceLG,
        AppTheme.spaceLG,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: kBrandGradient,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radius2XL),
          bottomRight: Radius.circular(AppTheme.radius2XL),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColor.accentColor.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName == null || firstName!.isEmpty
                          ? 'Hi, traveler'
                          : 'Hi, $firstName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: 46,
                  height: 46,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          const Text(
            'Find a verified local helper in minutes.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Primary Instant CTA
// ============================================================================

class _PrimaryInstantCta extends StatefulWidget {
  final VoidCallback onTap;
  const _PrimaryInstantCta({required this.onTap});

  @override
  State<_PrimaryInstantCta> createState() => _PrimaryInstantCtaState();
}

class _PrimaryInstantCtaState extends State<_PrimaryInstantCta> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColor.accentColor, AppColor.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AppColor.secondaryColor.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: const Text(
                        'INSTANT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Book a helper now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'On-demand, helpers respond in minutes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Secondary Scheduled CTA (softer)
// ============================================================================

class _SecondaryScheduledCta extends StatelessWidget {
  final VoidCallback onTap;
  const _SecondaryScheduledCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(
              color: AppColor.lightBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColor.secondaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: AppColor.secondaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Plan ahead',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pick a future date and confirm with a helper',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColor.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColor.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Why RAFIQ trust strip
// ============================================================================

class _WhyRafiqStrip extends StatelessWidget {
  const _WhyRafiqStrip();

  @override
  Widget build(BuildContext context) {
    final items = const [
      _WhyChipData(
        icon: Icons.verified_user_rounded,
        title: 'Verified',
        subtitle: 'Helpers',
        color: AppColor.accentColor,
      ),
      _WhyChipData(
        icon: Icons.location_on_rounded,
        title: 'Live',
        subtitle: 'Tracking',
        color: AppColor.secondaryColor,
      ),
      _WhyChipData(
        icon: Icons.public_rounded,
        title: 'Local',
        subtitle: 'Expertise',
        color: AppColor.warningColor,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _WhyChip(data: items[i])),
          if (i != items.length - 1) const SizedBox(width: AppTheme.spaceSM),
        ],
      ],
    );
  }
}

class _WhyChipData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _WhyChipData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _WhyChip extends StatelessWidget {
  final _WhyChipData data;
  const _WhyChip({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSM,
        vertical: AppTheme.spaceMD,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppColor.lightBorder),
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
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            data.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            data.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColor.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Active trip card
// ============================================================================

class _ActiveTripCard extends StatelessWidget {
  final BookingDetailEntity booking;
  final VoidCallback onTap;

  const _ActiveTripCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destination =
        booking.destinationName ?? booking.destinationCity;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(color: AppColor.lightBorder),
          boxShadow: [
            BoxShadow(
              color: AppColor.secondaryColor.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
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
                    color:
                        AppColor.secondaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    color: AppColor.secondaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: Text(
                    'Your active trip',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColor.lightTextSecondary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                BookingStatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'Trip to $destination',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
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
                  color: AppColor.lightTextSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.helper?.name ?? 'Awaiting helper',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColor.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text(
                      'Open trip',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
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

class _ActiveTripSkeleton extends StatelessWidget {
  const _ActiveTripSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppColor.lightBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBlock(width: 140, height: 14),
          SizedBox(height: 14),
          _ShimmerBlock(width: 220, height: 18),
          SizedBox(height: 8),
          _ShimmerBlock(width: 160, height: 14),
          SizedBox(height: 16),
          _ShimmerBlock(width: double.infinity, height: 36),
        ],
      ),
    );
  }
}

// ============================================================================
// Recent trip card
// ============================================================================

class _RecentTripCard extends StatelessWidget {
  final BookingDetailEntity booking;
  final VoidCallback onTap;

  const _RecentTripCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destination =
        booking.destinationName ?? booking.destinationCity;
    final dateLabel = booking.requestedDate.toLocal();
    final formatted = DateFormat('MMM d').format(dateLabel);
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: AppColor.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColor.lightBorder,
                    backgroundImage: booking.helper?.profileImageUrl != null
                        ? NetworkImage(booking.helper!.profileImageUrl!)
                        : null,
                    child: booking.helper?.profileImageUrl == null
                        ? const Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: AppColor.primaryColor,
                          )
                        : null,
                  ),
                  const Spacer(),
                  BookingStatusChip(status: booking.status, dense: true),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Text(
                destination,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: AppColor.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatted,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColor.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (booking.finalPrice != null)
                Row(
                  children: [
                    Text(
                      '${booking.finalPrice!.toStringAsFixed(0)} ${booking.currency ?? 'EGP'}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColor.accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Estimate pending',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColor.lightTextSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Recent trips skeleton
// ============================================================================

class _RecentTripsSkeleton extends StatelessWidget {
  const _RecentTripsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppTheme.spaceMD),
        itemBuilder: (_, __) => Container(
          width: 220,
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: AppColor.lightBorder),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ShimmerCircle(size: 32),
                  Spacer(),
                  _ShimmerBlock(width: 60, height: 18),
                ],
              ),
              SizedBox(height: 14),
              _ShimmerBlock(width: 140, height: 16),
              SizedBox(height: 6),
              _ShimmerBlock(width: 80, height: 12),
              Spacer(),
              _ShimmerBlock(width: 90, height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Empty state
// ============================================================================

class _EmptyTripsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyTripsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppColor.lightBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColor.accentColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: AppColor.accentColor,
              size: 36,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'No trips yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Book your first helper and start exploring.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColor.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMD),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.bolt_rounded),
              label: const Text(
                'Book a helper now',
                style: TextStyle(fontWeight: FontWeight.w700),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppColor.errorColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: AppColor.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColor.errorColor),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(
              'Could not load trips: $message',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColor.errorColor,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: AppColor.errorColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Shimmer primitives
// ============================================================================

class _ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  const _ShimmerBlock({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColor.lightBorder,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  final double size;
  const _ShimmerCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColor.lightBorder,
        shape: BoxShape.circle,
      ),
    );
  }
}

