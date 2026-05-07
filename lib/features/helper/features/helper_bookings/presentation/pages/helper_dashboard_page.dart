import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:toury/features/helper/features/helper_bookings/domain/entities/helper_availability_state.dart';
import 'package:toury/features/helper/features/helper_bookings/domain/entities/helper_dashboard_entity.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/services/auth_service.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../../../auth/data/datasources/helper_local_data_source.dart';
import '../../../helper_location/presentation/cubit/helper_location_cubit.dart';
import '../../../helper_location/presentation/cubit/location_status_cubits.dart';
import '../../../helper_location/presentation/widgets/helper_location_status_widget.dart';
import '../../../helper_service_areas/presentation/widgets/service_area_status_widget.dart';
import '../../../helper_invoices/presentation/widgets/earnings_preview_card.dart';

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
  }

  Future<void> _loadAll({bool force = false}) async {
    // 1. Auth/Token Check
    final token = sl<AuthService>().getToken();
    if (token == null || token.isEmpty) {
      debugPrint('❌ [Dashboard] No token found, redirecting to login');
      context.go(AppRouter.helperLogin);
      return;
    }

    try {
      // 2. Load Dashboard Info (to get availability state)
      if (force) {
        await _dashCubit.refresh(silent: true);
      } else {
        await _dashCubit.loadOnce();
      }
      
      final dashState = _dashCubit.state;
      if (dashState is HelperDashboardLoaded) {
        final availability = dashState.dashboard.availabilityState;
        
        // 3. Initialize Location Service & SignalR
        // 4. Start Tracking if applicable
        final trackingOk = await _locCubit.initialize(token, availability: availability);
        
        if (!trackingOk && availability == HelperAvailabilityState.availableNow) {
          debugPrint('⚠️ [Dashboard] Tracking failed to start while Online');
        }

        // 5. Load associated data
        await Future.wait([
          _activeCubit.load(silent: true),
          _requestsCubit.load(silent: true),
          _statusCubit.loadStatus(force: force),
        ]);
      }
    } catch (e) {
      debugPrint('❌ [Dashboard] Error during initialization: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _dashCubit),
        BlocProvider.value(value: _availCubit),
        BlocProvider.value(value: _activeCubit),
        BlocProvider.value(value: _requestsCubit),
        BlocProvider.value(value: _locCubit),
        BlocProvider.value(value: _statusCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<HelperAvailabilityCubit, HelperAvailabilityStatus>(
            listener: (context, state) {
              if (state is AvailabilityError) {
                _showSnack(context, state.message, isError: true);
              } else if (state is AvailabilityUpdated) {
                _availCubit.setCurrentStatus(state.status);
                _dashCubit.updateLocalAvailability(state.status);
                _locCubit.setAvailabilityState(state.status);
                _dashCubit.refresh(silent: true);

                if (state.status == HelperAvailabilityState.availableNow) {
                  _startAutoTracking();
                  _requestsCubit.load(silent: true);
                } else if (state.status == HelperAvailabilityState.offline) {
                  _locCubit.setAvailabilityState(HelperAvailabilityState.offline);
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
            onRefresh: () async => _loadAll(force: true),
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
      expandedHeight: 106,
      floating: false,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLG,
            44,
            AppTheme.spaceLG,
            0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 2),
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
                    'Helper',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
              onStatusChanged: (s) async {
                HapticService.medium();
                if (_availCubit.state is AvailabilityUpdating) return;
                if (dashboard.availabilityState == s) return;

                if (dashboard.activeTrip != null && s != HelperAvailabilityState.offline) {
                  _showSnack(context, 'You cannot change availability during an active trip', isError: true);
                  return;
                }

                if (s == HelperAvailabilityState.availableNow) {
                  _locCubit.setAvailabilityState(HelperAvailabilityState.availableNow);
                  final helper = await sl<HelperLocalDataSource>().getCurrentHelper();
                  if (!context.mounted) return;
                  final token = helper?.token ?? sl<AuthService>().getToken() ?? '';
                  if (token.isEmpty) {
                    _showSnack(context, 'Session expired. Please login again.', isError: true);
                    _locCubit.setAvailabilityState(dashboard.availabilityState);
                    return;
                  }
                  final ok = await _locCubit.initialize(token);
                  if (!ok) return;
                }

                _availCubit.update(s);
              },
            ),
          ),
          const SizedBox(height: AppTheme.spaceXL),

          BlocBuilder<ActiveBookingCubit, ActiveBookingState>(
            builder: (context, state) {
              if (state is ActiveBookingLoaded && state.booking != null) {
                final s = state.booking!.status.toLowerCase();
                if (s.contains('complet') || s.contains('cancel') || s == 'ended') {
                  return const SizedBox.shrink();
                }

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
    if (helper?.token != null) _locCubit.initialize(helper!.token!);
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