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
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../../../auth/data/datasources/helper_local_data_source.dart';
import '../../../helper_location/presentation/cubit/helper_location_cubit.dart';
import '../../../helper_location/presentation/cubit/location_status_cubits.dart';
import '../../../helper_location/presentation/widgets/helper_location_status_widget.dart';
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
  late final IncomingRequestsCubit _requestsCubit;
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
    _requestsCubit = sl<IncomingRequestsCubit>();
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
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_dashCubit.state is HelperDashboardLoaded) {
        final currentStatus = (_dashCubit.state as HelperDashboardLoaded).dashboard.availabilityState;
        if (currentStatus == HelperAvailabilityState.availableNow) {
          _dashCubit.refresh();
          _activeCubit.load(silent: true);
          _requestsCubit.load(silent: true);
          _statusCubit.loadStatus();
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _dashCubit.close();
    _availCubit.close();
    _activeCubit.close();
    _requestsCubit.close();
    _locCubit.close();
    _statusCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                  _startPolling();
                  _startAutoTracking();
                  _requestsCubit.load();
                } else if (state.status == HelperAvailabilityState.offline) {
                  _locCubit.stopTracking();
                  _refreshTimer?.cancel();
                } else if (state.status == HelperAvailabilityState.busy) {
                  _refreshTimer?.cancel();
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
          backgroundColor: theme.scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: () async => _loadAll(),
            color: theme.colorScheme.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(AppTheme.spaceLG, 50, AppTheme.spaceLG, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
                ),
                child: Center(
                  child: Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 28),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                    ),
                  ),
                  Text(
                    'Captain',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _IconButton(
                icon: Icons.notifications_none_rounded, 
                onTap: () {
                   HapticService.light();
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
              onStatusChanged: (s) async {
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
                }
                
                _availCubit.update(s);
              },
            ),
          ),
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
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        children: List.generate(4, (i) => _ShimmerBox(height: i == 0 ? 120 : 100)),
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
              onPressed: _loadAll, 
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: isDark ? Colors.white : Colors.black,
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
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceSM),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 22),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  const _ShimmerBox({required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCardColor : AppColor.lightCardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
    );
  }
}
