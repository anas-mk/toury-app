import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../auth/data/datasources/helper_local_data_source.dart';
import '../../data/services/helper_location_signalr_service.dart';
import '../cubit/helper_location_cubit.dart';
import '../cubit/location_status_cubits.dart';
import '../../../helper_bookings/presentation/cubit/helper_bookings_cubits.dart';
import '../../../helper_bookings/domain/entities/helper_booking_entities.dart';

class HelperLocationPage extends StatefulWidget {
  const HelperLocationPage({super.key});

  @override
  State<HelperLocationPage> createState() => _HelperLocationPageState();
}

class _HelperLocationPageState extends State<HelperLocationPage> {
  late final HelperLocationCubit _locationCubit;
  late final LocationStatusCubit _statusCubit;
  late final HelperAvailabilityCubit _availabilityCubit;
  final MapController _mapController = MapController();
  bool _following = true;

  @override
  void initState() {
    super.initState();
    // Using singletons from DI
    _locationCubit = sl<HelperLocationCubit>();
    _statusCubit = sl<LocationStatusCubit>();
    _availabilityCubit = sl<HelperAvailabilityCubit>();
    
    _initTracking();
    _statusCubit.loadStatus();
  }

  Future<void> _initTracking() async {
    final helper = await sl<HelperLocalDataSource>().getCurrentHelper();
    if (helper?.token != null) {
      // startTracking now handles duplicate prevention internally
      _locationCubit.startTracking(helper!.token!);
    }
  }

  @override
  void dispose() {
    // IMPORTANT: Do NOT close singleton cubits here. 
    // They are managed by the DI container or higher-level pages.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _locationCubit),
        BlocProvider.value(value: _statusCubit),
        BlocProvider.value(value: _availabilityCubit),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
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
                LatLng initialCenter = const LatLng(0, 0);
                if (state is HelperLocationTracking) {
                  initialCenter = LatLng(state.location.latitude, state.location.longitude);
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 15,
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture) setState(() => _following = false);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                    ),
                    if (state is HelperLocationTracking) ...[
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(state.location.latitude, state.location.longitude),
                            radius: 100,
                            useRadiusInMeter: true,
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                            borderColor: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(state.location.latitude, state.location.longitude),
                            width: 60,
                            height: 60,
                            child: _LocationMarker(heading: state.location.heading ?? 0),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),

            // ── Top Bar ──────────────────────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              child: _TopStatusBar(),
            ),

            // ── Bottom Panel ─────────────────────────────────────────────────────
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              child: _BottomControlPanel(
                following: _following,
                onRecenter: () {
                  setState(() => _following = true);
                  final state = _locationCubit.state;
                  if (state is HelperLocationTracking) {
                    _mapController.move(
                      LatLng(state.location.latitude, state.location.longitude),
                      15,
                    );
                  }
                },
              ),
            ),

            // ── Back Button ──────────────────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => context.pop(),
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
  const _LocationMarker({required this.heading});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        Transform.rotate(
          angle: (heading * (3.1415926535 / 180)),
          child: const Icon(
            Icons.navigation_rounded,
            color: Color(0xFF6C63FF),
            size: 40,
          ),
        ),
      ],
    );
  }
}

class _TopStatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          BlocBuilder<HelperLocationCubit, HelperLocationState>(
            builder: (context, state) {
              bool connected = false;
              if (state is HelperLocationTracking) {
                connected = state.connectionState == SignalRConnectionState.connected;
              }
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: connected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (connected ? Colors.green : Colors.red).withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Live Connection',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                BlocBuilder<HelperLocationCubit, HelperLocationState>(
                  builder: (context, state) {
                    String status = 'Disconnected';
                    if (state is HelperLocationTracking) {
                      status = state.connectionState.name.toUpperCase();
                    }
                    return Text(status,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11));
                  },
                ),
              ],
            ),
          ),
          _EligibilityBadge(),
        ],
      ),
    );
  }
}

class _EligibilityBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationStatusCubit, LocationStatusState>(
      builder: (context, state) {
        bool eligible = false;
        if (state is LocationStatusLoaded) {
          eligible = state.status.isFresh;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (eligible ? Colors.green : Colors.orange).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: (eligible ? Colors.green : Colors.orange).withValues(alpha: 0.3)),
          ),
          child: Text(
            eligible ? 'ELIGIBLE' : 'STALE',
            style: TextStyle(
              color: eligible ? Colors.green : Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

class _BottomControlPanel extends StatelessWidget {
  final bool following;
  final VoidCallback onRecenter;

  const _BottomControlPanel({required this.following, required this.onRecenter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: BlocBuilder<HelperAvailabilityCubit, HelperAvailabilityState>(
                  builder: (context, state) {
                    final isOnline = state is AvailabilityUpdated && state.status == AvailabilityStatus.availableNow;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isOnline ? 'You are Online' : 'You are Offline', 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(isOnline ? 'Streaming location live' : 'Location sync paused',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                      ],
                    );
                  },
                ),
              ),
              if (!following)
                IconButton.filled(
                  onPressed: onRecenter,
                  icon: const Icon(Icons.my_location_rounded),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/helper-eligibility-debug'),
                  icon: const Icon(Icons.bug_report_rounded, size: 18),
                  label: const Text('Debug'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BlocBuilder<HelperAvailabilityCubit, HelperAvailabilityState>(
                  builder: (context, state) {
                    final isOnline = state is AvailabilityUpdated && state.status == AvailabilityStatus.availableNow;
                    final isUpdating = state is AvailabilityUpdating;
                    
                    return ElevatedButton.icon(
                      onPressed: isUpdating ? null : () {
                        final newStatus = isOnline ? AvailabilityStatus.offline : AvailabilityStatus.availableNow;
                        context.read<HelperAvailabilityCubit>().update(newStatus);
                      },
                      icon: isUpdating 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(isOnline ? Icons.power_settings_new_rounded : Icons.play_arrow_rounded),
                      label: Text(isOnline ? 'Go Offline' : 'Go Online'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOnline ? const Color(0xFFFF6B6B) : const Color(0xFF00C896),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
