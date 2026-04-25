import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/helper/features/helper_location/presentation/cubit/helper_location_cubit.dart';
import 'package:toury/features/helper/features/helper_location/presentation/cubit/location_status_cubits.dart';
import 'package:toury/features/helper/features/helper_location/presentation/widgets/helper_location_status_widget.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../../../auth/data/datasources/helper_local_data_source.dart';
import '../../../helper_service_areas/presentation/widgets/service_area_status_widget.dart';
import '../../../helper_invoices/presentation/widgets/earnings_preview_card.dart';
import '../../../helper_ratings/presentation/pages/helper_ratings_page.dart';
import '../../../helper_reports/presentation/pages/helper_reports_page.dart';
import '../../../helper_reports/presentation/cubit/helper_reports_cubit.dart';
import '../../../helper_sos/presentation/pages/helper_sos_page.dart';
import '../../../helper_sos/presentation/cubit/helper_sos_cubit.dart';

class HelperDashboardPage extends StatefulWidget {
  const HelperDashboardPage({super.key});

  @override
  State<HelperDashboardPage> createState() => _HelperDashboardPageState();
}

class _HelperDashboardPageState extends State<HelperDashboardPage>
    with SingleTickerProviderStateMixin {
  late final HelperDashboardCubit _dashCubit;
  late final HelperAvailabilityCubit _availCubit;
  late final ActiveBookingCubit _activeCubit;
  late final HelperLocationCubit _locCubit;
  late final LocationStatusCubit _statusCubit;
  Timer? _refreshTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _dashCubit = sl<HelperDashboardCubit>();
    _availCubit = sl<HelperAvailabilityCubit>();
    _activeCubit = sl<ActiveBookingCubit>();
    _locCubit = sl<HelperLocationCubit>();
    _statusCubit = sl<LocationStatusCubit>();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadAll();
    _startPolling();
  }

  void _loadAll() {
    _dashCubit.load();
    _activeCubit.load();
    _statusCubit.loadStatus();
  }

  void _startPolling() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _dashCubit.refresh();
      _activeCubit.load(silent: true);
      _statusCubit.loadStatus();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _dashCubit.close();
    _availCubit.close();
    _activeCubit.close();
    _locCubit.close();
    _statusCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _dashCubit),
        BlocProvider.value(value: _availCubit),
        BlocProvider.value(value: _activeCubit),
        BlocProvider.value(value: _locCubit),
        BlocProvider.value(value: _statusCubit),
        BlocProvider(create: (context) => sl<HelperReportsCubit>()..loadReports()),
        BlocProvider(create: (context) => sl<HelperSosCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<HelperAvailabilityCubit, HelperAvailabilityState>(
            listener: (context, state) {
              if (state is AvailabilityError) {
                _showSnack(context, state.message, isError: true);
              } else if (state is AvailabilityUpdated) {
                _showSnack(context, 'Status: ${_statusLabel(state.status)}');
                _dashCubit.refresh();
                
                // Auto-behavior for location tracking
                if (state.status == AvailabilityStatus.availableNow) {
                  _startAutoTracking();
                } else if (state.status == AvailabilityStatus.offline) {
                  _locCubit.stopTracking();
                }
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: const Color(0xFF0A0E1A),
          body: RefreshIndicator(
            onRefresh: () async => _loadAll(),
            color: const Color(0xFF6C63FF),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: BlocBuilder<HelperDashboardCubit, HelperDashboardState>(
                    builder: (context, state) {
                      if (state is HelperDashboardLoading) return _buildShimmer();
                      if (state is HelperDashboardLoaded) {
                        return _buildBody(context, state.dashboard);
                      }
                      if (state is HelperDashboardError) {
                        return _buildError(context, state.message);
                      }
                      return _buildShimmer();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0D1120),
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1F3C), Color(0xFF0A0E1A)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Good ${_greeting()},',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Captain Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              BlocBuilder<HelperDashboardCubit, HelperDashboardState>(
                buildWhen: (p, c) => c is HelperDashboardLoaded,
                builder: (context, state) {
                  final rating = state is HelperDashboardLoaded ? state.dashboard.rating : 0.0;
                  return _RatingBadge(rating: rating);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HelperDashboard dashboard) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvailabilityCard(
            currentStatus: dashboard.availabilityState,
            pulseAnimation: _pulseAnimation,
            onStatusChanged: (s) => _availCubit.update(s),
          ),
          const SizedBox(height: 16),
          // Active trip card (conditional)
          BlocBuilder<ActiveBookingCubit, ActiveBookingState>(
            buildWhen: (p, c) => c is ActiveBookingLoaded || c is ActiveBookingError,
            builder: (context, state) {
              if (state is ActiveBookingLoaded && state.booking != null) {
                return Column(
                  children: [
                    _ActiveTripCard(booking: state.booking!),
                    const SizedBox(height: 16),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const HelperLocationStatusWidget(),
          const SizedBox(height: 12),
          const ServiceAreaStatusCard(),
          const SizedBox(height: 12),
          const EarningsPreviewCard(),
          const SizedBox(height: 12),
          _ReputationCard(
            rating: dashboard.rating,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelperRatingsPage()),
            ),
          ),
          const SizedBox(height: 16),
          // Stats grid
          _StatsGrid(dashboard: dashboard),
          const SizedBox(height: 20),
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<ActiveBookingCubit, ActiveBookingState>(
            buildWhen: (p, c) => c is ActiveBookingLoaded,
            builder: (context, state) {
              final hasActive = state is ActiveBookingLoaded && state.booking != null;
              return _QuickActionsGrid(hasActiveTrip: hasActive);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          5,
          (i) => _ShimmerBox(
            height: i == 0 ? 110 : (i == 1 ? 140 : 80),
            margin: const EdgeInsets.only(bottom: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, color: Color(0xFFFF6B6B), size: 44),
            ),
            const SizedBox(height: 20),
            const Text('Could not load dashboard', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.white38, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _loadAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  String _statusLabel(AvailabilityStatus s) {
    switch (s) {
      case AvailabilityStatus.availableNow:  return 'Available Now';
      case AvailabilityStatus.scheduledOnly: return 'Scheduled Only';
      case AvailabilityStatus.busy:          return 'Busy';
      case AvailabilityStatus.offline:       return 'Offline';
    }
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFFF6B6B) : const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _startAutoTracking() async {
    final helper = await sl<HelperLocalDataSource>().getCurrentHelper();
    if (helper?.token != null) {
      _locCubit.startTracking(helper!.token!);
    }
  }
}

// ── Shimmer Placeholder ──────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double height;
  final EdgeInsets margin;
  const _ShimmerBox({required this.height, required this.margin});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [
              Color(0xFF1A1F3C),
              Color(0xFF242A4A),
              Color(0xFF1A1F3C),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Availability Card ────────────────────────────────────────────────────────

class _AvailabilityCard extends StatelessWidget {
  final AvailabilityStatus currentStatus;
  final Animation<double> pulseAnimation;
  final ValueChanged<AvailabilityStatus> onStatusChanged;

  const _AvailabilityCard({
    required this.currentStatus,
    required this.pulseAnimation,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = currentStatus == AvailabilityStatus.availableNow;
    return BlocBuilder<HelperAvailabilityCubit, HelperAvailabilityState>(
      builder: (context, availState) {
        final isUpdating = availState is AvailabilityUpdating;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isOnline
                  ? [const Color(0xFF00C896), const Color(0xFF007A5E)]
                  : [const Color(0xFF1E2340), const Color(0xFF141829)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isOnline
                    ? const Color(0xFF00C896).withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: pulseAnimation,
                    builder: (_, __) => Transform.scale(
                      scale: isOnline ? pulseAnimation.value : 1.0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.white : Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          boxShadow: isOnline
                              ? [BoxShadow(color: Colors.white.withValues(alpha: 0.6), blurRadius: 8)]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnline ? 'Online — Ready for requests' : 'Currently Offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  if (isUpdating)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AvailabilityStatus.values.map((s) {
                    final selected = s == currentStatus;
                    return GestureDetector(
                      onTap: isUpdating ? null : () => onStatusChanged(s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _label(s),
                          style: TextStyle(
                            color: selected
                                ? (isOnline ? const Color(0xFF007A5E) : const Color(0xFF2A2F4C))
                                : Colors.white,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _label(AvailabilityStatus s) {
    switch (s) {
      case AvailabilityStatus.availableNow:  return '🟢 Available';
      case AvailabilityStatus.scheduledOnly: return '📅 Scheduled';
      case AvailabilityStatus.busy:          return '🔴 Busy';
      case AvailabilityStatus.offline:       return '⚫ Offline';
    }
  }
}

// ── Active Trip Card ─────────────────────────────────────────────────────────

class _ActiveTripCard extends StatelessWidget {
  final HelperBooking booking;
  const _ActiveTripCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        AppRouter.helperActiveBooking.replaceAll('/:id', ''),
        extra: booking.id,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF3B38B5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusPill(label: '🔴  ACTIVE TRIP'),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              booking.travelerName,
              style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.flag_rounded, color: Colors.white60, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.destinationLocation,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TripCTA(
                    label: 'Manage Trip',
                    icon: Icons.navigation_rounded,
                    onTap: () => context.push(
                      AppRouter.helperActiveBooking.replaceAll('/:id', ''),
                      extra: booking.id,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TripCTA(
                    label: 'Details',
                    icon: Icons.info_outline_rounded,
                    outline: true,
                    onTap: () => context.push('/helper-booking-details/${booking.id}'),
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

class _StatusPill extends StatelessWidget {
  final String label;
  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}

class _TripCTA extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outline;
  const _TripCTA({required this.label, required this.icon, required this.onTap, this.outline = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: outline ? Colors.transparent : Colors.white,
          border: outline ? Border.all(color: Colors.white.withValues(alpha: 0.5)) : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: outline ? Colors.white : const Color(0xFF6C63FF), size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: outline ? Colors.white : const Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final HelperDashboard dashboard;
  const _StatsGrid({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _S('Today\'s Earnings', '\$${dashboard.todayEarnings.toStringAsFixed(0)}', Icons.attach_money, const Color(0xFF00C896)),
      _S('Pending Requests', '${dashboard.pendingRequestsCount}', Icons.inbox_rounded, const Color(0xFFFFAB40)),
      _S('Upcoming Trips', '${dashboard.upcomingTripsCount}', Icons.event_rounded, const Color(0xFF6C63FF)),
      _S('Acceptance Rate', '${(dashboard.acceptanceRate * 100).toStringAsFixed(0)}%', Icons.thumb_up_alt_rounded, const Color(0xFF26C6DA)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      children: stats.map((s) => _StatCard(s: s)).toList(),
    );
  }
}

class _S {
  final String label, value;
  final IconData icon;
  final Color color;
  const _S(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _S s;
  const _StatCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: s.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(s.icon, color: s.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.value, style: TextStyle(color: s.color, fontSize: 21, fontWeight: FontWeight.bold)),
              Text(s.label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions Grid ───────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final bool hasActiveTrip;
  const _QuickActionsGrid({required this.hasActiveTrip});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _A('Requests', Icons.inbox_rounded, const Color(0xFFFFAB40),
          () => context.push(AppRouter.helperRequests)),
      _A('Upcoming', Icons.event_rounded, const Color(0xFF6C63FF),
          () => context.push(AppRouter.helperUpcoming)),
      if (hasActiveTrip)
        _A('Active Trip', Icons.navigation_rounded, const Color(0xFFFF6B6B),
            () => context.push(AppRouter.helperActiveBooking.replaceAll('/:id', ''), extra: '')),
      _A('Earnings', Icons.bar_chart_rounded, const Color(0xFF00C896),
          () => context.push(AppRouter.helperEarnings)),
      _A('History', Icons.history_rounded, const Color(0xFF26C6DA),
          () => context.push(AppRouter.helperHistory)),
      _A('My Areas', Icons.map_rounded, const Color(0xFFFF8C69),
          () => context.push(AppRouter.helperServiceAreas)),
      _A('Invoices', Icons.receipt_long_rounded, const Color(0xFF26C6DA),
          () => context.push(AppRouter.helperInvoices)),
      _A('Reports', Icons.flag_rounded, const Color(0xFFFF6B6B),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelperReportsPage()))),
      _A('SOS', Icons.sos_rounded, Colors.red,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelperSosPage()))),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.map((a) => _ActionTile(a: a)).toList(),
    );
  }
}

class _A {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _A(this.label, this.icon, this.color, this.onTap);
}

class _ActionTile extends StatelessWidget {
  final _A a;
  const _ActionTile({required this.a});

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 32 - 36) / 4;
    return GestureDetector(
      onTap: a.onTap,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: a.color.withValues(alpha: 0.25)),
              ),
              child: Icon(a.icon, color: a.color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              a.label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rating Badge ─────────────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFAB40).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFAB40).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFAB40), size: 17),
          const SizedBox(width: 4),
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : '--',
            style: const TextStyle(
              color: Color(0xFFFFAB40),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReputationCard extends StatelessWidget {
  final double rating;
  final VoidCallback onTap;

  const _ReputationCard({required this.rating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E2340), Color(0xFF141829)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Reputation',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Travelers love your service!',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const Text(
                  'View Reviews',
                  style: TextStyle(color: Color(0xFF6C63FF), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
