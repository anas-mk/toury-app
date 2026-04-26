import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../../../../core/di/injection_container.dart';
import '../../../auth/data/datasources/helper_local_data_source.dart';
import '../../data/services/helper_location_signalr_service.dart';
import '../cubit/helper_location_cubit.dart';
import '../cubit/location_status_cubits.dart';
import '../../../helper_bookings/presentation/cubit/helper_bookings_cubits.dart';
import '../../../helper_bookings/domain/entities/helper_booking_entities.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';

class HelperLocationPage extends StatefulWidget {
  const HelperLocationPage({super.key});

  @override
  State<HelperLocationPage> createState() => _HelperLocationPageState();
}

class _HelperLocationPageState extends State<HelperLocationPage> with SingleTickerProviderStateMixin {
  late final HelperLocationCubit _locationCubit;
  late final LocationStatusCubit _statusCubit;
  late final HelperAvailabilityCubit _availabilityCubit;
  final MapController _mapController = MapController();
  bool _following = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _locationCubit = sl<HelperLocationCubit>();
    _statusCubit = sl<LocationStatusCubit>();
    _availabilityCubit = sl<HelperAvailabilityCubit>();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initTracking();
    _statusCubit.loadStatus();
  }

  Future<void> _initTracking() async {
    final helper = await sl<HelperLocalDataSource>().getCurrentHelper();
    if (helper?.token != null) {
      _locationCubit.startTracking(helper!.token!);
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
    final isDark = theme.brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _locationCubit),
        BlocProvider.value(value: _statusCubit),
        BlocProvider.value(value: _availabilityCubit),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            // ── Map Layer ────────────────────────────────────────────────────────
            BlocConsumer<HelperLocationCubit, HelperLocationState>(
              listener: (context, state) {
                if (state is HelperLocationTracking && _following) {
                  _mapController.move(
                    LatLng(state.location.latitude, state.location.longitude),
                    _mapController.camera.zoom,
                  );
                }
              },
              builder: (context, state) {
                LatLng initialCenter = const LatLng(30.0444, 31.2357);
                if (state is HelperLocationTracking) {
                  initialCenter = LatLng(state.location.latitude, state.location.longitude);
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 16,
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture) setState(() => _following = false);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: isDark 
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                    ),
                    if (state is HelperLocationTracking) ...[
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(state.location.latitude, state.location.longitude),
                            radius: 150,
                            useRadiusInMeter: true,
                            color: theme.colorScheme.secondary.withOpacity(0.1),
                            borderColor: theme.colorScheme.secondary.withOpacity(0.3),
                            borderStrokeWidth: 1,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(state.location.latitude, state.location.longitude),
                            width: 80,
                            height: 80,
                            child: _LocationMarker(
                              heading: state.location.heading ?? 0,
                              pulseAnimation: _pulseController,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),

            // ── Top Glass Bar ───────────────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + AppTheme.spaceSM,
              left: AppTheme.spaceMD,
              right: AppTheme.spaceMD,
              child: _TopStatusBar(),
            ),

            // ── Floating Action Buttons ──────────────────────────────────────────
            Positioned(
              right: AppTheme.spaceMD,
              bottom: MediaQuery.of(context).padding.bottom + 220,
              child: Column(
                children: [
                  _MapControlBtn(
                    icon: Icons.my_location_rounded,
                    onTap: () {
                      setState(() => _following = true);
                      final state = _locationCubit.state;
                      if (state is HelperLocationTracking) {
                        _mapController.move(LatLng(state.location.latitude, state.location.longitude), 16);
                      }
                    },
                    isActive: _following,
                  ),
                  SizedBox(height: AppTheme.spaceSM),
                  _MapControlBtn(
                    icon: Icons.add_rounded,
                    onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                  ),
                  SizedBox(height: AppTheme.spaceSM),
                  _MapControlBtn(
                    icon: Icons.remove_rounded,
                    onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                  ),
                ],
              ),
            ),

            // ── Bottom Panel ─────────────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomControlPanel(),
            ),

            // ── Back Button ──────────────────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + AppTheme.spaceSM,
              left: AppTheme.spaceLG,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 18),
                      onPressed: () => context.pop(),
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

class _LocationMarker extends StatelessWidget {
  final double heading;
  final Animation<double> pulseAnimation;
  const _LocationMarker({required this.heading, required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 60 * pulseAnimation.value,
              height: 60 * pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withOpacity(0.2 * (1 - pulseAnimation.value)),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Transform.rotate(
              angle: (heading * (3.1415926535 / 180)),
              child: Icon(
                Icons.navigation_rounded,
                color: theme.colorScheme.secondary,
                size: 44,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopStatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              BlocBuilder<HelperLocationCubit, HelperLocationState>(
                builder: (context, state) {
                  bool connected = state is HelperLocationTracking && 
                      state.connectionState == SignalRConnectionState.connected;
                  return _StatusIndicator(isActive: connected);
                },
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('TRACKING ENGINE',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.onSurface,
                        )),
                    BlocBuilder<HelperLocationCubit, HelperLocationState>(
                      builder: (context, state) {
                        String status = 'INITIALIZING...';
                        if (state is HelperLocationTracking) {
                          status = state.connectionState.name.toUpperCase();
                        }
                        return Text(status,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                            ));
                      },
                    ),
                  ],
                ),
              ),
              const _EligibilityBadge(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isActive;
  const _StatusIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? AppColor.accentColor : AppColor.errorColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isActive ? AppColor.accentColor : AppColor.errorColor).withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _EligibilityBadge extends StatelessWidget {
  const _EligibilityBadge();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<LocationStatusCubit, LocationStatusState>(
      builder: (context, state) {
        bool eligible = state is LocationStatusLoaded && 
            state.status.isLocationFresh && state.status.canReceiveInstantRequests;
        final color = eligible ? AppColor.accentColor : AppColor.warningColor;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(eligible ? Icons.verified_user_rounded : Icons.info_outline_rounded, 
                  color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                eligible ? 'ACTIVE' : 'STALE',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  const _MapControlBtn({required this.icon, required this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? theme.colorScheme.secondary : theme.colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: Icon(icon, color: isActive ? Colors.white : theme.colorScheme.onSurface, size: 24),
          ),
        ),
      ),
    );
  }
}

class _BottomControlPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radius2XL)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(AppTheme.spaceLG, AppTheme.spaceLG, AppTheme.spaceLG, bottomPadding + AppTheme.spaceLG),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radius2XL)),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 24),
              BlocBuilder<HelperAvailabilityCubit, HelperAvailabilityStatus>(
                builder: (context, state) {
                  final isOnline = state is AvailabilityUpdated && state.status == HelperAvailabilityState.availableNow;
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isOnline ? 'Broadcasting Active' : 'System Standby', 
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(isOnline ? 'Streaming High-Precision GPS data' : 'Tracking and visibility suspended',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                          ],
                        ),
                      ),
                      _PulseIndicator(isActive: isOnline),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/helper/eligibility-debug'),
                      icon: const Icon(Icons.analytics_outlined, size: 20),
                      label: const Text('DIAGNOSTICS'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLG)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BlocBuilder<HelperAvailabilityCubit, HelperAvailabilityStatus>(
                      builder: (context, state) {
                        final isOnline = state is AvailabilityUpdated && state.status == HelperAvailabilityState.availableNow;
                        final isUpdating = state is AvailabilityUpdating;
                        
                        return ElevatedButton.icon(
                          onPressed: isUpdating ? null : () {
                            final newStatus = isOnline ? HelperAvailabilityState.offline : HelperAvailabilityState.availableNow;
                            context.read<HelperAvailabilityCubit>().update(newStatus);
                          },
                          icon: isUpdating 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(isOnline ? Icons.power_settings_new_rounded : Icons.radar_rounded),
                          label: Text(isOnline ? 'GO OFFLINE' : 'GO ONLINE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOnline ? AppColor.errorColor : AppColor.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLG)),
                          ),
                        );
                      },
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
}

class _PulseIndicator extends StatefulWidget {
  final bool isActive;
  const _PulseIndicator({required this.isActive});
  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? AppColor.accentColor : AppColor.errorColor;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5 * _controller.value),
                blurRadius: 10 * _controller.value,
                spreadRadius: 4 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
