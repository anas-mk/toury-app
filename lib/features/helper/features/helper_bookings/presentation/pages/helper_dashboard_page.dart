import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/widgets/hero_header.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../domain/entities/helper_dashboard_entity.dart';
import '../../domain/entities/helper_availability_state.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../cubit/helper_polling_orchestrator.dart';
import '../../../auth/data/datasources/helper_local_data_source.dart';
import '../../../helper_location/presentation/cubit/helper_location_cubit.dart';
import '../../../helper_location/presentation/cubit/location_status_cubits.dart';
import '../../../helper_location/presentation/widgets/helper_location_status_widget.dart';
import '../../../helper_service_areas/presentation/widgets/service_area_status_widget.dart';
import '../../../helper_invoices/presentation/widgets/earnings_preview_card.dart';
import '../../../helper_reports/presentation/cubit/helper_reports_cubit.dart';
import '../../../helper_sos/presentation/cubit/helper_sos_cubit.dart';

import '../widgets/dashboard/availability_toggle_card.dart';
import '../widgets/dashboard/active_trip_card.dart';
import '../widgets/dashboard/stats_grid.dart';
import '../widgets/dashboard/quick_actions_grid.dart';
import '../widgets/dashboard/reputation_card.dart';
import '../widgets/dashboard/helper_availability_action_button.dart';
import '../../../../../../core/theme/brand_typography.dart';
import 'package:shimmer/shimmer.dart';

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
  late final IncomingRequestsCubit _requestsCubit;
  late final HelperLocationCubit _locCubit;
  late final LocationStatusCubit _statusCubit;
  late final HelperPollingOrchestrator _orchestrator;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _dashCubit = sl<HelperDashboardCubit>();
    _availCubit = sl<HelperAvailabilityCubit>();
    _activeCubit = sl<ActiveBookingCubit>();
    _requestsCubit = sl<IncomingRequestsCubit>();
    _locCubit = sl<HelperLocationCubit>();
    _statusCubit = sl<LocationStatusCubit>();
    _orchestrator = HelperPollingOrchestrator(
      _dashCubit,
      _activeCubit,
      _requestsCubit,
      _statusCubit,
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initLoad();
    _orchestrator.start();
  }

  void _initLoad() {
    _dashCubit.loadOnce();
    _activeCubit.load();
    _statusCubit.loadStatus();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _dashCubit.refresh(silent: true),
      _activeCubit.load(silent: true),
      _statusCubit.loadStatus(),
    ]);
  }

  @override
  void dispose() {
    _orchestrator.close();
    _pulseController.dispose();
    _dashCubit.close();
    _availCubit.close();
    _activeCubit.close();
    _requestsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _dashCubit),
        BlocProvider.value(value: _availCubit),
        BlocProvider.value(value: _activeCubit),
        BlocProvider.value(value: _requestsCubit),
        BlocProvider.value(value: _locCubit),
        BlocProvider.value(value: _statusCubit),
        BlocProvider(create: (context) => sl<HelperReportsCubit>()..loadReports()),
        BlocProvider(create: (context) => sl<HelperSosCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<HelperAvailabilityCubit, HelperAvailabilityStatus>(
            listener: (context, state) {
              if (state is AvailabilityError) {
                _showSnack(context, state.message, isError: true);
              } else if (state is AvailabilityUpdated) {
                _dashCubit.updateLocalAvailability(state.status);
                _dashCubit.refresh();
                
                if (state.status == HelperAvailabilityState.availableNow) {
                  _orchestrator.start();
                  _startAutoTracking();
                  _requestsCubit.load();
                } else if (state.status == HelperAvailabilityState.offline) {
                  _locCubit.disable();
                  _orchestrator.stop();
                } else if (state.status == HelperAvailabilityState.busy) {
                  _orchestrator.stop();
                }
              }
            },
          ),
          BlocListener<HelperLocationCubit, HelperLocationState>(
            listener: (context, state) {
              if (state is HelperLocationPermissionDenied) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Location permission required to go Online.'),
                    backgroundColor: AppColor.errorColor,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Settings',
                      textColor: Colors.white,
                      onPressed: () => Geolocator.openAppSettings(),
                    ),
                  ),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: BrandTokens.bgSoft,
          body: RefreshIndicator.adaptive(
            onRefresh: _refreshAll,
            color: BrandTokens.primaryBlue,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _buildAppBar(context),
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

  Widget _buildAppBar(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: HeroSliverHeader(
        title: 'Welcome back,\nCaptain',
        showBack: false,
        height: 200,
        trailing: _IconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {
            HapticService.light();
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HelperDashboardEntity dashboard) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spaceLG),
          FadeInSlide(
            duration: const Duration(milliseconds: 400),
            child: AvailabilityToggleCard(
              currentStatus: dashboard.availabilityState,
              pulseAnimation: _pulseAnimation,
              onStatusChanged: (s) => _handleStatusChange(context, dashboard, s),
            ),
          ),

          const SizedBox(height: AppTheme.spaceMD),
          // FadeInSlide(
          //   delay: const Duration(milliseconds: 120),
          //   child: HelperAvailabilityActionButton(
          //     currentStatus: dashboard.availabilityState,
          //     onUpdated: () => context.go(AppRouter.helperRequests),
          //   ),
          // ),
          
          if (dashboard.availabilityState == HelperAvailabilityState.offline) ...[
            const SizedBox(height: AppTheme.spaceLG),
            FadeInSlide(
              delay: const Duration(milliseconds: 450),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: BrandTokens.primaryBlue.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Ready to work?',
                      style: BrandTypography.title(color: BrandTokens.primaryBlue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Go online to see new trip requests near you.',
                      style: BrandTypography.caption(color: BrandTokens.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleStatusChange(context, dashboard, HelperAvailabilityState.availableNow),
                        icon: const Icon(Icons.bolt_rounded, color: Colors.white),
                        label: const Text('GO ONLINE NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandTokens.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          shadowColor: BrandTokens.primaryBlue.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spaceXL),
          
          BlocBuilder<ActiveBookingCubit, ActiveBookingState>(
            builder: (context, state) {
              if (state is ActiveBookingLoaded && state.booking != null) {
                return FadeInSlide(
                  delay: const Duration(milliseconds: 100),
                  child: Column(
                    children: [
                      ActiveTripCard(booking: state.booking!),
                      const SizedBox(height: AppTheme.spaceXL),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const FadeInSlide(delay: Duration(milliseconds: 150), child: SectionHeader(title: 'Overview')),
          const SizedBox(height: AppTheme.spaceMD),
          FadeInSlide(delay: const Duration(milliseconds: 200), child: StatsGrid(dashboard: dashboard)),
          const SizedBox(height: AppTheme.spaceXL),

          const FadeInSlide(delay: Duration(milliseconds: 250), child: SectionHeader(title: 'Service & Location')),
          const SizedBox(height: AppTheme.spaceMD),
          const FadeInSlide(delay: Duration(milliseconds: 300), child: HelperLocationStatusWidget()),
          const SizedBox(height: AppTheme.spaceSM),
          const FadeInSlide(delay: Duration(milliseconds: 350), child: ServiceAreaStatusCard()),
          const SizedBox(height: AppTheme.spaceXL),

          const FadeInSlide(delay: Duration(milliseconds: 400), child: SectionHeader(title: 'Financials')),
          const SizedBox(height: AppTheme.spaceMD),
          const FadeInSlide(delay: Duration(milliseconds: 450), child: EarningsPreviewCard()),
          const SizedBox(height: AppTheme.spaceXL),

          const FadeInSlide(delay: Duration(milliseconds: 500), child: SectionHeader(title: 'Reputation')),
          const SizedBox(height: AppTheme.spaceMD),
          FadeInSlide(
            delay: const Duration(milliseconds: 550),
            child: ReputationCard(
              rating: dashboard.rating,
              onTap: () {
                HapticService.light();
                context.push(AppRouter.helperRatings);
              },
            ),
          ),
          const SizedBox(height: AppTheme.spaceXL),

          const FadeInSlide(delay: Duration(milliseconds: 600), child: SectionHeader(title: 'Quick Actions')),
          const SizedBox(height: AppTheme.spaceMD),
          const FadeInSlide(delay: Duration(milliseconds: 650), child: QuickActionsGrid()),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _ShimmerBox(height: 160),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _ShimmerBox(height: 100)),
              const SizedBox(width: 16),
              Expanded(child: _ShimmerBox(height: 100)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _ShimmerBox(height: 100)),
              const SizedBox(width: 16),
              Expanded(child: _ShimmerBox(height: 100)),
            ],
          ),
          const SizedBox(height: 24),
          _ShimmerBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColor.errorColor, size: 48),
            const SizedBox(height: AppTheme.spaceLG),
            Text(
              'Something went wrong', 
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              message, 
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: AppTheme.spaceXL),
            ElevatedButton(
              onPressed: _initLoad,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColor.errorColor : AppColor.accentColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleStatusChange(BuildContext context, HelperDashboardEntity dashboard, HelperAvailabilityState s) async {
    HapticService.medium();
    if (_availCubit.state is AvailabilityUpdating) return;
    if (dashboard.availabilityState == s) return;
    
    if (dashboard.activeTrip != null && s != HelperAvailabilityState.offline) {
      _showSnack(context, 'You cannot change availability during an active trip', isError: true);
      return;
    }
    
    if (s == HelperAvailabilityState.availableNow) {
      final token = sl<SharedPreferences>().getString('auth_token') ?? '';
      final success = await _locCubit.requestPermissionAndInitialize(token);
      if (!success) {
        _dashCubit.refresh();
        return;
      }
      
      _availCubit.update(s);
      // Navigate to bookings center when going online
      if (mounted) {
        context.push(AppRouter.helperBookings);
      }
    } else {
      _availCubit.update(s);
    }
  }

  Future<void> _startAutoTracking() async {
    final helper = await sl<HelperLocalDataSource>().getCurrentHelper();
    if (helper?.token != null) _locCubit.enable(helper!.token!);
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: BrandTokens.heading(fontSize: 20),
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
        padding: const EdgeInsets.all(AppTheme.spaceSM),
        decoration: BoxDecoration(
          color: BrandTokens.surfaceWhite.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: BrandTokens.surfaceWhite, size: 24),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  const _ShimmerBox({required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: BrandTokens.borderSoft.withValues(alpha: 0.3),
      highlightColor: BrandTokens.borderSoft.withValues(alpha: 0.1),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
