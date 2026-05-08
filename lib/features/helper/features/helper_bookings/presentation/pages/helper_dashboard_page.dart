import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:toury/features/helper/features/helper_bookings/domain/entities/helper_availability_state.dart';
import 'package:toury/features/helper/features/helper_bookings/domain/entities/helper_dashboard_entity.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/utils/currency_format.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../../domain/entities/helper_booking_status_x.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../../../auth/data/datasources/helper_local_data_source.dart';
import '../../../helper_location/presentation/cubit/helper_location_cubit.dart';
import '../../../helper_location/presentation/cubit/location_status_cubits.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';

// Modularized Dashboard Widgets
import '../widgets/dashboard/availability_toggle_card.dart';
import '../widgets/dashboard/active_trip_card.dart';
import '../widgets/dashboard/stats_grid.dart';

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
  late final HelperHistoryCubit _historyCubit;
  late final HelperLocationCubit _locCubit;
  late final LocationStatusCubit _statusCubit;
  late final ProfileCubit _profileCubit;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _dashCubit = sl<HelperDashboardCubit>();
    _availCubit = sl<HelperAvailabilityCubit>();
    _activeCubit = sl<ActiveBookingCubit>();
    _requestsCubit = sl<IncomingRequestsCubit>();
    _historyCubit = sl<HelperHistoryCubit>();
    _locCubit = sl<HelperLocationCubit>();
    _statusCubit = sl<LocationStatusCubit>();
    _profileCubit = sl<ProfileCubit>()..fetchProfileBundle();
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
    final token = sl<AuthService>().getToken();
    if (token == null || token.isEmpty) {
      debugPrint('❌ [Dashboard] No token found, redirecting to login');
      context.go(AppRouter.helperLogin);
      return;
    }

    try {
      if (force) {
        await _dashCubit.refresh(silent: true);
      } else {
        await _dashCubit.loadOnce();
      }

      final dashState = _dashCubit.state;
      if (dashState is HelperDashboardLoaded) {
        final availability = dashState.dashboard.availabilityState;

        final trackingOk = await _locCubit.initialize(
          token,
          availability: availability,
        );

        if (!trackingOk &&
            availability == HelperAvailabilityState.availableNow) {
          debugPrint('⚠️ [Dashboard] Tracking failed to start while Online');
        }

        await Future.wait([
          _activeCubit.load(silent: true),
          _requestsCubit.load(silent: true),
          _statusCubit.loadStatus(force: force),
          _historyCubit.load(),
        ]);
      }
    } catch (e) {
      debugPrint('❌ [Dashboard] Error during initialization: $e');
    }
  }

  @override
  void dispose() {
    _profileCubit.close();
    _historyCubit.close();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _dashCubit),
        BlocProvider.value(value: _availCubit),
        BlocProvider.value(value: _activeCubit),
        BlocProvider.value(value: _requestsCubit),
        BlocProvider.value(value: _historyCubit),
        BlocProvider.value(value: _locCubit),
        BlocProvider.value(value: _statusCubit),
        BlocProvider.value(value: _profileCubit),
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
                  _locCubit.setAvailabilityState(
                    HelperAvailabilityState.offline,
                  );
                }
              }
            },
          ),
          BlocListener<HelperLocationCubit, HelperLocationState>(
            listener: (context, state) {
              if (state is HelperLocationPermissionDenied) {
                AppSnackbar.show(
                  context,
                  message: 'Location permission required to go Online.',
                  tone: AppSnackTone.danger,
                  actionLabel: 'Settings',
                  onAction: () => Geolocator.openAppSettings(),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: palette.scaffold,
          body: RefreshIndicator(
            onRefresh: () async => _loadAll(force: true),
            color: palette.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: FadeInSlide(
                    duration: const Duration(milliseconds: 500),
                    child: _DashboardHeader(),
                  ),
                ),
                SliverToBoxAdapter(
                  child:
                      BlocBuilder<HelperDashboardCubit, HelperDashboardState>(
                        builder: (context, state) {
                          if (state is HelperDashboardLoading) {
                            return const _ShimmerBody();
                          }
                          if (state is HelperDashboardLoaded) {
                            return _buildBody(context, state.dashboard);
                          }
                          if (state is HelperDashboardError) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: AppErrorState(
                                message: state.message,
                                onRetry: _loadAll,
                              ),
                            );
                          }
                          return const _ShimmerBody();
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

  Widget _buildBody(BuildContext context, HelperDashboardEntity dashboard) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          FadeInSlide(
            duration: const Duration(milliseconds: 400),
            child: AvailabilityToggleCard(
              currentStatus: dashboard.availabilityState,
              pulseAnimation: _pulseAnimation,
              onStatusChanged: (s) async {
                HapticService.medium();
                if (_availCubit.state is AvailabilityUpdating) return;
                if (dashboard.availabilityState == s) return;

                if (dashboard.activeTrip != null &&
                    s != HelperAvailabilityState.offline) {
                  _showSnack(
                    context,
                    'You cannot change availability during an active trip',
                    isError: true,
                  );
                  return;
                }

                if (s == HelperAvailabilityState.availableNow) {
                  _locCubit.setAvailabilityState(
                    HelperAvailabilityState.availableNow,
                  );
                  final helper = await sl<HelperLocalDataSource>()
                      .getCurrentHelper();
                  if (!context.mounted) return;
                  final token =
                      helper?.token ?? sl<AuthService>().getToken() ?? '';
                  if (token.isEmpty) {
                    _showSnack(
                      context,
                      'Session expired. Please login again.',
                      isError: true,
                    );
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
          const SizedBox(height: 20),

          BlocBuilder<ActiveBookingCubit, ActiveBookingState>(
            builder: (context, state) {
              if (state is ActiveBookingLoaded && state.booking != null) {
                final s = state.booking!.status.toLowerCase();
                if (s.contains('complet') ||
                    s.contains('cancel') ||
                    s == 'ended') {
                  return const SizedBox.shrink();
                }

                return FadeInSlide(
                  delay: const Duration(milliseconds: 100),
                  child: Column(
                    children: [
                      ActiveTripCard(booking: state.booking!),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          FadeInSlide(
            delay: const Duration(milliseconds: 150),
            child: const _SectionTitle(
              title: 'Today\'s Overview',
              subtitle: 'Your performance at a glance',
            ),
          ),
          const SizedBox(height: 12),
          FadeInSlide(
            delay: const Duration(milliseconds: 200),
            child: StatsGrid(dashboard: dashboard),
          ),
          const SizedBox(height: 28),

          FadeInSlide(
            delay: const Duration(milliseconds: 250),
            child: _SectionTitle(
              title: 'Recent Bookings',
              subtitle: 'Your latest completed trips',
              actionLabel: 'See all',
              onAction: () {
                HapticService.light();
                context.push(AppRouter.helperHistory);
              },
            ),
          ),
          const SizedBox(height: 12),
          FadeInSlide(
            delay: const Duration(milliseconds: 300),
            child: const _RecentBookingsSection(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    AppSnackbar.show(
      context,
      message: msg,
      tone: isError ? AppSnackTone.danger : AppSnackTone.success,
    );
  }

  Future<void> _startAutoTracking() async {
    final helper = await sl<HelperLocalDataSource>().getCurrentHelper();
    if (helper?.token != null) _locCubit.initialize(helper!.token!);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  HEADER
// ──────────────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    if (hour < 12) {
      greeting = 'Good morning';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      greeting = 'Good afternoon';
      greetingIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Good evening';
      greetingIcon = Icons.nightlight_round;
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: BlocBuilder<ProfileCubit, ProfileState>(
          buildWhen: (p, c) =>
              p.profile?.profileImageUrl != c.profile?.profileImageUrl ||
              p.profile?.fullName != c.profile?.fullName,
          builder: (context, profileState) {
            final profile = profileState.profile;
            final imageUrl = profile?.profileImageUrl;
            final firstName = (profile?.fullName.isNotEmpty ?? false)
                ? profile!.fullName.split(' ').first
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 8),
                  child: Text(
                    'RAFIQ',
                    style: TextStyle(
                      inherit: false,
                      fontFamily: 'PermanentMarker',
                      fontSize: 22,
                      letterSpacing: 1.2,
                      color: palette.primary,
                      height: 1,
                      shadows: [
                        Shadow(
                          color: palette.primary.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticService.light();
                          context.push(AppRouter.helperAccount);
                        },
                        customBorder: const CircleBorder(),
                        child: _GradientAvatar(imageUrl: imageUrl),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                greetingIcon,
                                size: 14,
                                color: palette.textMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                greeting,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: palette.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            firstName != null ? '$firstName 👋' : 'Partner Hub',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                              fontSize: 20,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    BlocBuilder<HelperDashboardCubit, HelperDashboardState>(
                      buildWhen: (p, c) => c is HelperDashboardLoaded,
                      builder: (context, state) {
                        if (state is HelperDashboardLoaded) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _RatingChip(
                              rating: state.dashboard.rating,
                              ratingCount: state.dashboard.ratingCount,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    BlocBuilder<IncomingRequestsCubit, IncomingRequestsState>(
                      builder: (context, state) {
                        int? count;
                        if (state is IncomingRequestsLoaded) {
                          count = state.totalCount;
                        }
                        if (state is IncomingRequestsEmpty) count = 0;
                        return _NotificationButton(unreadCount: count ?? 0);
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  RATING CHIP (header)
// ──────────────────────────────────────────────────────────────────────────────

class _RatingChip extends StatelessWidget {
  final double rating;
  final int ratingCount;

  const _RatingChip({required this.rating, required this.ratingCount});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final hasRatings = ratingCount > 0;
    final accent = const Color(0xFFFFB020);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push(AppRouter.helperRatings);
        },
        borderRadius: BorderRadius.circular(99),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: palette.isDark ? 0.22 : 0.14),
                accent.withValues(alpha: palette.isDark ? 0.10 : 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: accent, size: 16),
              const SizedBox(width: 4),
              Text(
                hasRatings ? rating.toStringAsFixed(1) : 'New',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  final String? imageUrl;
  const _GradientAvatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final resolved = ApiConfig.resolveImageUrl(imageUrl);
    final hasImage = resolved.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            palette.primary,
            const Color(0xFF7B61FF),
            const Color(0xFFFF8C42),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.scaffold,
        ),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.primary.withValues(alpha: 0.10),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Image.network(
                  resolved,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackIcon(palette),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: palette.primary,
                        ),
                      ),
                    );
                  },
                )
              : _fallbackIcon(palette),
        ),
      ),
    );
  }

  Widget _fallbackIcon(AppColors palette) {
    return Icon(Icons.person_rounded, color: palette.primary, size: 22);
  }
}

class _NotificationButton extends StatelessWidget {
  final int unreadCount;
  const _NotificationButton({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRouter.helperRequests),
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
                border: Border.all(color: palette.border),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: palette.textPrimary,
                size: 20,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B5C),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: palette.scaffold, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  SECTION TITLE
// ──────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: palette.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (onAction == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: titleColumn,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: titleColumn),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(99),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: palette.primary.withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (actionLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          actionLabel!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: palette.primary,
                            height: 1,
                          ),
                        ),
                      ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: palette.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  SHIMMER BODY
// ──────────────────────────────────────────────────────────────────────────────

class _ShimmerBody extends StatelessWidget {
  const _ShimmerBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          _ShimmerBox(height: 130),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _ShimmerBox(height: 110)),
              SizedBox(width: 12),
              Expanded(child: _ShimmerBox(height: 110)),
            ],
          ),
          SizedBox(height: 16),
          _ShimmerBox(height: 90),
          SizedBox(height: 16),
          _ShimmerBox(height: 90),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double height;
  const _ShimmerBox({required this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment(-1 + t * 2, 0),
                  end: Alignment(t * 2, 0),
                  colors: [
                    palette.surface.withValues(alpha: 0),
                    palette.border.withValues(alpha: 0.5),
                    palette.surface.withValues(alpha: 0),
                  ],
                ).createShader(rect);
              },
              blendMode: BlendMode.srcOver,
              child: Container(color: Colors.transparent),
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  RECENT BOOKINGS SECTION
// ──────────────────────────────────────────────────────────────────────────────

class _RecentBookingsSection extends StatelessWidget {
  const _RecentBookingsSection();

  static const int _maxItems = 3;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HelperHistoryCubit, HelperHistoryState>(
      builder: (context, state) {
        if (state is HelperHistoryLoading || state is HelperHistoryInitial) {
          return const Column(
            children: [
              _ShimmerBox(height: 88),
              SizedBox(height: 12),
              _ShimmerBox(height: 88),
            ],
          );
        }
        if (state is HelperHistoryError) {
          return _RecentEmptyCard(
            icon: Icons.cloud_off_rounded,
            title: 'Couldn\'t load history',
            message: state.message,
          );
        }
        if (state is HelperHistoryLoaded) {
          if (state.bookings.isEmpty) {
            return const _RecentEmptyCard(
              icon: Icons.history_rounded,
              title: 'No recent bookings yet',
              message:
                  'Completed and past trips will show up here for quick reference.',
            );
          }
          final items = state.bookings.take(_maxItems).toList();
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _RecentBookingTile(booking: items[i]),
                if (i != items.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _RecentBookingTile extends StatelessWidget {
  final HelperBooking booking;
  const _RecentBookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final tone = _statusTone(booking, palette);

    final dateLabel = DateFormat('MMM d • h:mm a').format(booking.startTime);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push(
            AppRouter.helperBookingDetails.replaceFirst(':id', booking.id),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border, width: 0.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: palette.isDark ? 0.25 : 0.04,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _RecentAvatar(
                name: booking.travelerName,
                imageUrl: booking.travelerImage,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.travelerName.isNotEmpty
                                ? booking.travelerName
                                : 'Traveler',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(label: tone.label, color: tone.color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 13,
                          color: palette.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            booking.destinationCity.isNotEmpty
                                ? booking.destinationCity
                                : booking.destinationLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: palette.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: palette.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Money.egp(booking.payout),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: palette.primary,
                            height: 1,
                          ),
                        ),
                      ],
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

  _StatusTone _statusTone(HelperBooking b, AppColors palette) {
    if (b.isCompleted) {
      return const _StatusTone('Completed', Color(0xFF10B981));
    }
    if (b.isCancelled) {
      return const _StatusTone('Cancelled', Color(0xFFEF4444));
    }
    if (b.isActive) {
      return const _StatusTone('Active', Color(0xFF3B82F6));
    }
    if (b.isConfirmed) {
      return const _StatusTone('Confirmed', Color(0xFF8B5CF6));
    }
    return _StatusTone(b.status, palette.textMuted);
  }
}

class _StatusTone {
  final String label;
  final Color color;
  const _StatusTone(this.label, this.color);
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _RecentAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  const _RecentAvatar({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final resolved = ApiConfig.resolveImageUrl(imageUrl);
    final hasImage = resolved.isNotEmpty;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.primary.withValues(alpha: 0.10),
        border: Border.all(
          color: palette.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              resolved,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(palette),
            )
          : _initials(palette),
    );
  }

  Widget _initials(AppColors palette) {
    final initials = _initialsFromName(name);
    return Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: palette.primary,
          height: 1,
        ),
      ),
    );
  }

  String _initialsFromName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _RecentEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _RecentEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border, width: 0.6),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.primary.withValues(alpha: 0.08),
            ),
            child: Icon(icon, color: palette.primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: palette.textMuted,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
