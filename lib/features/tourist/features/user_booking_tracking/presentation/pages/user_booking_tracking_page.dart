import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/booking_status_cubit.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/booking_status_state.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/tracking_cubit.dart';
import '../cubit/tracking_state.dart';

class UserBookingTrackingPage extends StatefulWidget {
  final String bookingId;
  final LatLng? pickupLocation;
  final LatLng? destinationLocation;

  const UserBookingTrackingPage({
    super.key, 
    required this.bookingId,
    this.pickupLocation,
    this.destinationLocation,
  });

  @override
  State<UserBookingTrackingPage> createState() => _UserBookingTrackingPageState();
}

class _UserBookingTrackingPageState extends State<UserBookingTrackingPage> {
  final MapController _mapController = MapController();
  bool _following = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<TrackingCubit>()..startTracking(widget.bookingId)),
        BlocProvider(create: (_) => sl<BookingStatusCubit>()..refreshActiveBooking(widget.bookingId)),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            // ── Map Layer ────────────────────────────────────────────────────────
            BlocConsumer<TrackingCubit, TrackingState>(
              listener: (context, state) {
                if (state is TrackingActive && state.latestPoint != null && _following) {
                  _mapController.move(
                    LatLng(state.latestPoint!.latitude, state.latestPoint!.longitude),
                    _mapController.camera.zoom,
                  );
                }
              },
              builder: (context, state) {
                LatLng initialCenter = const LatLng(30.0444, 31.2357); // Default Cairo
                if (state is TrackingActive && state.latestPoint != null) {
                  initialCenter = LatLng(state.latestPoint!.latitude, state.latestPoint!.longitude);
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
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                    ),
                    if (state is TrackingActive && state.latestPoint != null) ...[
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(state.latestPoint!.latitude, state.latestPoint!.longitude),
                            width: 60,
                            height: 60,
                            child: _HelperMarker(heading: state.latestPoint!.heading ?? 0),
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
              left: 10,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColor.primaryColor, size: 20),
                  onPressed: () => context.pop(),
                ),
              ),
            ),

            // ── Status Badge ─────────────────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 15,
              left: 70,
              right: 70,
              child: _StatusBadge(bookingId: widget.bookingId),
            ),

            // ── Bottom Panel ─────────────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _TrackingBottomPanel(
                following: _following,
                onRecenter: () {
                  setState(() => _following = true);
                  final state = context.read<TrackingCubit>().state;
                  if (state is TrackingActive && state.latestPoint != null) {
                    _mapController.move(
                      LatLng(state.latestPoint!.latitude, state.latestPoint!.longitude),
                      15,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelperMarker extends StatelessWidget {
  final double heading;
  const _HelperMarker({required this.heading});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: (heading * (3.1415926535 / 180)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColor.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
          const Icon(
            Icons.navigation_rounded,
            color: AppColor.primaryColor,
            size: 40,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String bookingId;
  const _StatusBadge({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrackingCubit, TrackingState>(
      builder: (context, state) {
        String status = 'Tracking Helper';
        if (state is TrackingActive) {
          status = state.tracking.status;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.shadowLight(context),
            border: Border.all(color: AppColor.lightBorder),
          ),
          child: Text(
            status.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColor.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
        );
      },
    );
  }
}

class _TrackingBottomPanel extends StatelessWidget {
  final bool following;
  final VoidCallback onRecenter;

  const _TrackingBottomPanel({required this.following, required this.onRecenter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!following)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceMD),
              child: CustomButton(
                text: 'Recenter Map',
                variant: ButtonVariant.outlined,
                icon: Icons.my_location_rounded,
                onPressed: onRecenter,
              ),
            ),
          
          BlocBuilder<BookingStatusCubit, BookingStatusState>(
            builder: (context, state) {
              if (state is BookingStatusActive) {
                final booking = state.booking;
                return Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AppNetworkImage(
                            imageUrl: booking.helper?.profileImageUrl ?? '',
                            width: 50,
                            height: 50,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(booking.helper?.name ?? 'Helper', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              BlocBuilder<TrackingCubit, TrackingState>(
                                builder: (context, state) {
                                  if (state is TrackingActive && state.tracking.etaMinutes != null) {
                                    return Text(
                                      'Arriving in ${state.tracking.etaMinutes} mins',
                                      style: const TextStyle(color: AppColor.accentColor, fontWeight: FontWeight.bold),
                                    );
                                  }
                                  return const Text('Calculating ETA...', style: TextStyle(color: AppColor.lightTextSecondary));
                                },
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () => context.pushNamed('user-chat', pathParameters: {'id': booking.id}),
                          icon: const Icon(Icons.chat_bubble_rounded),
                          style: IconButton.styleFrom(backgroundColor: AppColor.primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceLG),
                    CustomButton(
                      text: 'Booking Details',
                      variant: ButtonVariant.text,
                      onPressed: () => context.pushNamed('booking-details', pathParameters: {'id': booking.id}),
                    ),
                  ],
                );
              }
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            },
          ),
        ],
      ),
    );
  }
}
