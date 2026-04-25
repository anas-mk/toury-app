import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/features/helper/features/helper_location/presentation/cubit/helper_location_cubit.dart';
import 'package:toury/features/helper/features/helper_location/presentation/cubit/location_status_cubits.dart';
import 'package:toury/features/helper/features/helper_location/presentation/widgets/helper_location_status_widget.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../../../auth/data/datasources/helper_local_data_source.dart';
import '../../../helper_service_areas/presentation/widgets/service_area_status_widget.dart';
import '../../../helper_invoices/presentation/widgets/earnings_preview_card.dart';
import '../../../helper_ratings/presentation/pages/helper_ratings_page.dart';
import '../../../helper_reports/presentation/cubit/helper_reports_cubit.dart';
import '../../../helper_sos/presentation/cubit/helper_sos_cubit.dart';

// Modularized Dashboard Widgets
import '../widgets/dashboard/availability_toggle_card.dart';
import '../widgets/dashboard/active_trip_card.dart';
import '../widgets/dashboard/stats_grid.dart';
import '../widgets/dashboard/quick_actions_grid.dart';
import '../widgets/dashboard/reputation_card.dart';

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
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
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
                _dashCubit.refresh();
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
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0D1120),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1F3C), Color(0xFF0A0E1A)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFF6C63FF),
                child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                  const Text(
                    'Captain',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Spacer(),
              _IconButton(icon: Icons.notifications_none_rounded, onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildBody(BuildContext context, HelperDashboard dashboard) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          FadeInSlide(
            duration: const Duration(milliseconds: 400),
            child: AvailabilityToggleCard(
              currentStatus: dashboard.availabilityState,
              pulseAnimation: _pulseAnimation,
              onStatusChanged: (s) {
                HapticService.medium();
                _availCubit.update(s);
              },
            ),
          ),
          const SizedBox(height: 24),
          
          BlocBuilder<ActiveBookingCubit, ActiveBookingState>(
            builder: (context, state) {
              if (state is ActiveBookingLoaded && state.booking != null) {
                return FadeInSlide(
                  delay: const Duration(milliseconds: 100),
                  child: Column(
                    children: [
                      ActiveTripCard(booking: state.booking!),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const FadeInSlide(delay: Duration(milliseconds: 150), child: SectionHeader(title: 'Overview')),
          const SizedBox(height: 12),
          FadeInSlide(delay: const Duration(milliseconds: 200), child: StatsGrid(dashboard: dashboard)),
          const SizedBox(height: 24),

          const FadeInSlide(delay: Duration(milliseconds: 250), child: SectionHeader(title: 'Service & Location')),
          const SizedBox(height: 12),
          const FadeInSlide(delay: Duration(milliseconds: 300), child: HelperLocationStatusWidget()),
          const SizedBox(height: 12),
          const FadeInSlide(delay: Duration(milliseconds: 350), child: ServiceAreaStatusCard()),
          const SizedBox(height: 24),

          const FadeInSlide(delay: Duration(milliseconds: 400), child: SectionHeader(title: 'Financials')),
          const SizedBox(height: 12),
          const FadeInSlide(delay: Duration(milliseconds: 450), child: EarningsPreviewCard()),
          const SizedBox(height: 24),

          const FadeInSlide(delay: Duration(milliseconds: 500), child: SectionHeader(title: 'Reputation')),
          const SizedBox(height: 12),
          FadeInSlide(
            delay: const Duration(milliseconds: 550),
            child: ReputationCard(
              rating: dashboard.rating,
              onTap: () {
                HapticService.light();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HelperRatingsPage()));
              },
            ),
          ),
          const SizedBox(height: 24),

          const FadeInSlide(delay: Duration(milliseconds: 600), child: SectionHeader(title: 'Quick Actions')),
          const SizedBox(height: 12),
          const FadeInSlide(delay: Duration(milliseconds: 650), child: QuickActionsGrid()),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(4, (i) => _ShimmerBox(height: i == 0 ? 120 : 100)),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            const Text('Something went wrong', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startAutoTracking() async {
    final helper = await sl<HelperLocalDataSource>().getCurrentHelper();
    if (helper?.token != null) _locCubit.startTracking(helper!.token!);
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  const _ShimmerBox({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}
