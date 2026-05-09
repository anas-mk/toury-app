// Full-screen route preview map pushed as a modal before the helper
// accepts a booking. Shows green pickup pin, red destination pin, and
// the real road route fetched from the Directions API.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../../../core/services/location/mapbox_directions_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/utils/currency_format.dart';
import '../../../../../../core/widgets/map_tracking_chrome.dart';
import '../../domain/entities/helper_booking_entities.dart';

class RoutePreviewPage extends StatefulWidget {
  final HelperBooking booking;

  const RoutePreviewPage({super.key, required this.booking});

  static Future<void> show(BuildContext context, HelperBooking booking) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => RoutePreviewPage(booking: booking),
      ),
    );
  }

  @override
  State<RoutePreviewPage> createState() => _RoutePreviewPageState();
}

class _RoutePreviewPageState extends State<RoutePreviewPage> {
  final _directions = MapboxDirectionsService();

  MapboxMap? _map;
  PointAnnotationManager? _pinManager;
  PolylineAnnotationManager? _lineManager;

  RouteResult? _route;
  bool _loading = true;
  String? _error;

  @override
  void dispose() {
    _pinManager = null;
    _lineManager = null;
    super.dispose();
  }

  void _onMapCreated(MapboxMap map) async {
    _map = map;
    map.compass.updateSettings(CompassSettings(enabled: false));
    map.logo.updateSettings(LogoSettings(enabled: false));
    map.attribution.updateSettings(AttributionSettings(enabled: false));
    map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

    _pinManager = await map.annotations.createPointAnnotationManager();
    _lineManager = await map.annotations.createPolylineAnnotationManager();

    unawaited(_fetchAndDraw());
  }

  Future<void> _fetchAndDraw() async {
    final b = widget.booking;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Draw pins first so the map shows something immediately.
      await _drawPins(b);

      // Fetch road route.
      final profile = b.requiresCar ? 'driving' : 'walking';
      final result = await _directions.getRoute(
        fromLat: b.pickupLat,
        fromLng: b.pickupLng,
        toLat: b.destinationLat,
        toLng: b.destinationLng,
        profile: profile,
      );

      if (!mounted) return;

      if (result != null && result.coordinates.isNotEmpty) {
        setState(() => _route = result);
        await _drawRoute(result);
      } else {
        // Straight-line fallback.
        await _lineManager?.create(
          PolylineAnnotationOptions(
            geometry: LineString(coordinates: [
              Position(b.pickupLng, b.pickupLat),
              Position(b.destinationLng, b.destinationLat),
            ]),
            lineColor: BrandTokens.primaryBlue.toARGB32(),
            lineWidth: 3.5,
            lineOpacity: 0.65,
          ),
        );
      }

      // Fit camera so both points are visible with padding.
      _fitBounds(b);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _drawPins(HelperBooking b) async {
    await _pinManager?.deleteAll();
    final pickupBytes = await _buildPin(const ui.Color(0xFF34C759));
    final destBytes   = await _buildPin(const ui.Color(0xFFFF3B30));

    await _pinManager?.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(b.pickupLng, b.pickupLat)),
      image: pickupBytes,
      iconSize: 1.0,
      iconAnchor: IconAnchor.BOTTOM,
      symbolSortKey: 200,
    ));
    await _pinManager?.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(b.destinationLng, b.destinationLat)),
      image: destBytes,
      iconSize: 1.0,
      iconAnchor: IconAnchor.BOTTOM,
      symbolSortKey: 200,
    ));
  }

  Future<void> _drawRoute(RouteResult result) async {
    await _lineManager?.deleteAll();
    final positions = result.coordinates.map((c) => Position(c[0], c[1])).toList();
    await _lineManager?.create(PolylineAnnotationOptions(
      geometry: LineString(coordinates: positions),
      lineColor: BrandTokens.primaryBlue.toARGB32(),
      lineWidth: 5.0,
      lineOpacity: 0.88,
    ));
  }

  void _fitBounds(HelperBooking b) {
    final minLat = math.min(b.pickupLat, b.destinationLat);
    final maxLat = math.max(b.pickupLat, b.destinationLat);
    final minLng = math.min(b.pickupLng, b.destinationLng);
    final maxLng = math.max(b.pickupLng, b.destinationLng);

    _map?.setCamera(CameraOptions(
      center: Point(coordinates: Position(
        (minLng + maxLng) / 2,
        (minLat + maxLat) / 2,
      )),
      zoom: _zoomForDelta(maxLat - minLat, maxLng - minLng),
    ));
  }

  double _zoomForDelta(double dLat, double dLng) {
    final maxDelta = math.max(dLat, dLng);
    if (maxDelta < 0.005) return 15.5;
    if (maxDelta < 0.02)  return 14.0;
    if (maxDelta < 0.08)  return 12.5;
    if (maxDelta < 0.3)   return 11.0;
    return 9.5;
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final palette = AppColors.of(context);
    final initialCenter = Position(
      (b.pickupLng + b.destinationLng) / 2,
      (b.pickupLat + b.destinationLat) / 2,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          Positioned.fill(
            child: MapWidget(
              key: const ValueKey('routePreviewMap'),
              cameraOptions: CameraOptions(
                center: Point(coordinates: initialCenter),
                zoom: 12.0,
              ),
              styleUri: Theme.of(context).brightness == Brightness.dark
                  ? MapboxStyles.DARK
                  : MapboxStyles.LIGHT,
              onMapCreated: _onMapCreated,
            ),
          ),

          // Top gradient so back button stays readable.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.28],
                  ),
                ),
              ),
            ),
          ),

          // ── Loading overlay ──────────────────────────────────────────────
          if (_loading)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl,
                          vertical: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceElevated.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: palette.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Loading route…',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                color: palette.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Back button ──────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.lg,
            child: MapFloatingGlassButton(
              icon: Icons.arrow_back_rounded,
              tone: MapFloatingGlassTone.darkOnMap,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          // ── Retry button (on error) ───────────────────────────────────────
          if (_error != null && !_loading)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.sm,
              right: AppSpacing.lg,
              child: MapFloatingGlassButton(
                icon: Icons.refresh_rounded,
                tone: MapFloatingGlassTone.darkOnMap,
                onTap: _fetchAndDraw,
              ),
            ),

          // ── Bottom info card ─────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _RouteInfoCard(
              booking: b,
              route: _route,
              error: _error,
              loading: _loading,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<Uint8List> _buildPin(ui.Color color) async {
    const double w = 48, h = 64, r = 24.0, cx = 24.0, cy = 24.0;
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);

    canvas.drawCircle(
      const ui.Offset(cx, cy + 2),
      r,
      ui.Paint()
        ..color = ui.Color(0x33000000)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
    );
    canvas.drawCircle(const ui.Offset(cx, cy), r - 1, ui.Paint()..color = color);
    final tail = ui.Path()
      ..moveTo(cx - r * 0.38, cy + r * 0.70)
      ..lineTo(cx, h - 2)
      ..lineTo(cx + r * 0.38, cy + r * 0.70)
      ..close();
    canvas.drawPath(tail, ui.Paint()..color = color);
    canvas.drawCircle(const ui.Offset(cx, cy), r * 0.38,
        ui.Paint()..color = const ui.Color(0xCCFFFFFF));

    final pic = rec.endRecording();
    final img = await pic.toImage(w.toInt(), h.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}

// ── Bottom card ─────────────────────────────────────────────────────────────

class _RouteInfoCard extends StatelessWidget {
  final HelperBooking booking;
  final RouteResult? route;
  final String? error;
  final bool loading;

  const _RouteInfoCard({
    required this.booking,
    required this.route,
    required this.error,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: palette.surfaceElevated.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
            border: Border.all(
              color: palette.border.withValues(alpha: 0.30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.lg,
            AppSpacing.pageGutter,
            AppSpacing.lg + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle look
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),

              // Route distance + duration chips (or loading/error hint).
              if (!loading && error == null && route != null)
                _RouteChips(route: route!)
              else if (error != null)
                Text(
                  'Could not load route — map shows straight line',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.danger,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: AppSpacing.md),

              // Pickup row
              _LocationRow(
                color: const Color(0xFF34C759),
                label: 'Pickup',
                address: booking.pickupLocation,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Connector line
              Row(
                children: [
                  const SizedBox(width: 11),
                  Container(
                    width: 2,
                    height: 20,
                    color: palette.border,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Destination row
              _LocationRow(
                color: const Color(0xFFFF3B30),
                label: 'Destination',
                address: booking.destinationLocation,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Payout chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: palette.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: AppSize.iconSm,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      Money.egp(booking.payout),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'payout',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class _RouteChips extends StatelessWidget {
  final RouteResult route;
  const _RouteChips({required this.route});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: palette.textPrimary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.straighten_rounded, size: AppSize.iconMd, color: palette.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(route.distanceLabel, style: style),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Container(width: 1, height: 16, color: palette.border),
        ),
        Icon(Icons.schedule_rounded, size: AppSize.iconMd, color: palette.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(route.durationLabel, style: style),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  final Color color;
  final String label;
  final String address;

  const _LocationRow({
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(Icons.circle, size: 8, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                address.isEmpty ? '—' : address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
