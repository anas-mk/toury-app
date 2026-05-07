import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/booking_status_cubit.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/booking_status_state.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/tracking_cubit.dart';
import '../cubit/tracking_state.dart';

class UserBookingTrackingPage extends StatefulWidget {
  final String bookingId;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;

  const UserBookingTrackingPage({
    super.key,
    required this.bookingId,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
  });

  @override
  State<UserBookingTrackingPage> createState() =>
      _UserBookingTrackingPageState();
}

class _UserBookingTrackingPageState extends State<UserBookingTrackingPage> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _markerManager;
  bool _following = true;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<TrackingCubit>()..startTracking(widget.bookingId),
        ),
        BlocProvider(
          create: (_) =>
              sl<BookingStatusCubit>()..refreshActiveBooking(widget.bookingId),
        ),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            // ── Map Layer ────────────────────────────────────────────────────────
            BlocConsumer<TrackingCubit, TrackingState>(
              listener: (context, state) {
                if (state is TrackingActive &&
                    state.latestPoint != null &&
                    _following) {
                  _mapboxMap?.setCamera(CameraOptions(
                    center: Point(coordinates: Position(
                      state.latestPoint!.longitude,
                      state.latestPoint!.latitude,
                    )),
                    zoom: _mapboxMap == null ? 15 : null,
                  ));
                }
              },
              builder: (context, state) {
                double initialLat = 30.0444;
                double initialLng = 31.2357;
                if (state is TrackingActive && state.latestPoint != null) {
                  initialLat = state.latestPoint!.latitude;
                  initialLng = state.latestPoint!.longitude;
                }

                return MapWidget(
                  key: const ValueKey('trackingMap'),
                  cameraOptions: CameraOptions(
                    center: Point(coordinates: Position(initialLng, initialLat)),
                    zoom: 15.0,
                  ),
                  styleUri: MapboxStyles.LIGHT,
                  onMapCreated: (map) async {
                    _mapboxMap = map;
                    _markerManager = await map.annotations.createPointAnnotationManager();
                  },
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
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColor.primaryColor,
                    size: 20,
                  ),
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
                    _mapboxMap?.setCamera(CameraOptions(
                      center: Point(coordinates: Position(
                        state.latestPoint!.longitude,
                        state.latestPoint!.latitude,
                      )),
                      zoom: 15,
                    ));
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
              color: AppColor.primaryColor.withValues(alpha: 0.2),
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
            color: BrandTokens.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: BrandTokens.cardShadow,
            border: Border.all(color: BrandTokens.borderSoft),
          ),
          child: Text(
            status.toUpperCase().replaceAll('_', ' '),
            textAlign: TextAlign.center,
            style: BrandTokens.body(
              color: BrandTokens.primaryBlue,
              fontWeight: FontWeight.w900,
              fontSize: 12,
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

  const _TrackingBottomPanel({
    required this.following,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: BrandTokens.primaryBlue.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
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

          BlocBuilder<TrackingCubit, TrackingState>(
            builder: (context, trackingState) {
              if (trackingState is TrackingError) {
                return _TrackingMessage(
                  icon: Icons.wifi_off_rounded,
                  title: 'Tracking is not connected',
                  message: trackingState.message,
                );
              }
              if (trackingState is TrackingLoading) {
                return const _TrackingMessage(
                  icon: Icons.radar_rounded,
                  title: 'Connecting to helper location',
                  message:
                      'Fetching the latest location and opening realtime updates.',
                  loading: true,
                );
              }
              return BlocBuilder<BookingStatusCubit, BookingStatusState>(
                builder: (context, state) {
                  if (state is BookingStatusActive) {
                    final booking = state.booking;
                    final active = trackingState is TrackingActive
                        ? trackingState
                        : null;
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
                                  Text(
                                    booking.helper?.name ?? 'Helper',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: BrandTokens.heading(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    _trackingSubtitle(active),
                                    style: BrandTokens.body(
                                      color: BrandTokens.primaryBlue,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filled(
                              onPressed: () => context.pushNamed(
                                'user-chat',
                                pathParameters: {'id': booking.id},
                              ),
                              icon: const Icon(Icons.chat_bubble_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColor.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceLG),
                        if (active != null)
                          Row(
                            children: [
                              Expanded(
                                child: _MetricChip(
                                  icon: Icons.schedule_rounded,
                                  label: 'ETA',
                                  value: active.tracking.etaMinutes == null
                                      ? '--'
                                      : '${active.tracking.etaMinutes} min',
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceSM),
                              Expanded(
                                child: _MetricChip(
                                  icon: Icons.near_me_rounded,
                                  label: 'Distance',
                                  value:
                                      active.tracking.distanceToTarget == null
                                      ? '--'
                                      : '${active.tracking.distanceToTarget!.toStringAsFixed(1)} km',
                                ),
                              ),
                            ],
                          ),
                        if (active != null)
                          const SizedBox(height: AppTheme.spaceMD),
                        CustomButton(
                          text: 'Booking Details',
                          variant: ButtonVariant.text,
                          onPressed: () => context.pushNamed(
                            'booking-details',
                            pathParameters: {'id': booking.id},
                          ),
                        ),
                      ],
                    );
                  }
                  return const _TrackingMessage(
                    icon: Icons.route_rounded,
                    title: 'Loading booking',
                    message: 'Preparing helper and trip details.',
                    loading: true,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _trackingSubtitle(TrackingActive? active) {
    if (active?.tracking.etaMinutes != null) {
      return 'Arriving in ${active!.tracking.etaMinutes} mins';
    }
    if (active?.latestPoint != null) {
      return 'Live location connected';
    }
    return 'Waiting for first live location';
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSM),
      decoration: BoxDecoration(
        color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Row(
        children: [
          Icon(icon, color: BrandTokens.primaryBlue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: BrandTokens.body(fontSize: 11)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BrandTokens.numeric(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: BrandTokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool loading;

  const _TrackingMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Row(
        children: [
          loading
              ? const CircularProgressIndicator(color: BrandTokens.primaryBlue)
              : Icon(icon, color: BrandTokens.primaryBlue, size: 34),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BrandTokens.heading(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: BrandTokens.body(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
