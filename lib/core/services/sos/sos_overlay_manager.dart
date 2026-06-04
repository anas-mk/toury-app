import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../realtime/booking_realtime_event_bus.dart';
import '../sos/sos_service.dart';
import '../../di/injection_container.dart';
import '../../../features/user/features/user_booking/presentation/widgets/sos/sos_sheet.dart';

/// Global floating SOS pill shown while a trip is in-progress.
///
/// Call [bind] once in main() after the navigator key is ready.
/// The manager subscribes to [BookingRealtimeEventBus]:
///   • [BusBookingTripStarted] → shows the pill.
///   • [BusBookingTripEnded]   → hides the pill.
///
/// Call [suspend] / [resume] from pages that have their own SOS UI
/// (e.g. TripTrackingPage) to hide the pill without losing state.
class SosOverlayManager {
  SosOverlayManager._();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static StreamSubscription<BookingRealtimeBusEvent>? _busSub;
  static OverlayEntry? _entry;
  static String? _activeBookingId;
  static bool _suspended = false;

  // ── Public API ─────────────────────────────────────────────────────────────

  static void bind(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _busSub?.cancel();
    _busSub = BookingRealtimeEventBus.instance.stream.listen(_onBusEvent);
  }

  /// Hide the pill temporarily (e.g. when a page has its own SOS UI).
  /// The active booking id is preserved; call [resume] to re-show.
  static void suspend() {
    _suspended = true;
    _removeOverlay();
  }

  /// Re-show the pill if a trip is still active.
  static void resume() {
    _suspended = false;
    if (_activeBookingId != null) _showOverlay();
  }

  static void dispose() {
    _busSub?.cancel();
    _removeOverlay();
  }

  // ── Private ────────────────────────────────────────────────────────────────

  static void _onBusEvent(BookingRealtimeBusEvent event) {
    if (event is BusBookingTripStarted) {
      _activeBookingId = event.event.bookingId;
      if (!_suspended) _showOverlay();
    } else if (event is BusBookingTripEnded) {
      _removeOverlay();
      _activeBookingId = null;
    }
  }

  static void _showOverlay() {
    _removeOverlay();
    final overlay = _navigatorKey?.currentState?.overlay;
    if (overlay == null) return;
    _entry = OverlayEntry(builder: (_) => const _SosPill());
    overlay.insert(_entry!);
  }

  static void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  /// Shows the [SosSheet] bottom sheet and triggers the SOS on confirm.
  static Future<void> openSosSheet() async {
    final id = _activeBookingId;
    if (id == null || id.isEmpty) return;
    final ctx = _navigatorKey?.currentContext;
    if (ctx == null || !ctx.mounted) return;
    HapticFeedback.heavyImpact();

    final ok = await showSosSheet(
      ctx,
      onTrigger: (result) async {
        final trigger = await sl<SosService>().trigger(
          bookingId: id,
          reason: result.reason.apiValue,
          note: result.note,
        );
        if (trigger.success) return null;
        return trigger.message ?? 'Could not trigger SOS. Please try again.';
      },
    );

    if (ok != true) return;
    final freshCtx = _navigatorKey?.currentContext;
    if (freshCtx == null || !freshCtx.mounted) return;
    ScaffoldMessenger.maybeOf(freshCtx)?.showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Support has been alerted.'),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// ── Draggable floating SOS pill ───────────────────────────────────────────────

class _SosPill extends StatefulWidget {
  const _SosPill();

  @override
  State<_SosPill> createState() => _SosPillState();
}

class _SosPillState extends State<_SosPill>
    with SingleTickerProviderStateMixin {
  // Pulsing ring animation
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  late final Animation<double> _ring = CurvedAnimation(
    parent: _pulse,
    curve: Curves.easeOut,
  );

  // Drag position — initialised after first layout
  Offset? _position;
  bool _entered = false;

  static const double _size = 56;
  static const Color _red = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Offset _defaultPosition(BuildContext context) {
    final size   = MediaQuery.sizeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Offset(size.width - _size - 20, size.height - bottom - 160);
  }

  @override
  Widget build(BuildContext context) {
    _position ??= _defaultPosition(context);

    return Positioned(
      left: _position!.dx,
      top:  _position!.dy,
      child: AnimatedSlide(
        offset: _entered ? Offset.zero : const Offset(1.5, 0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: _entered ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: GestureDetector(
            onPanUpdate: (d) {
              if (!mounted) return;
              final sz  = MediaQuery.sizeOf(context);
              final bot = MediaQuery.paddingOf(context).bottom;
              setState(() {
                _position = Offset(
                  (_position!.dx + d.delta.dx).clamp(0, sz.width  - _size),
                  (_position!.dy + d.delta.dy).clamp(0, sz.height - bot - _size),
                );
              });
            },
            onTap: SosOverlayManager.openSosSheet,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              // Extra space for the pulsing ring so it's not clipped
              width:  _size + 20,
              height: _size + 20,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing expanding ring
                  AnimatedBuilder(
                    animation: _ring,
                    builder: (_, __) => Opacity(
                      opacity: (1 - _ring.value).clamp(0.0, 1.0),
                      child: Container(
                        width:  _size + _ring.value * 22,
                        height: _size + _ring.value * 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _red,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Main button — white circle with red icon
                  Container(
                    width:  _size,
                    height: _size,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _red, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _red.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emergency_rounded,
                      color: _red,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
