import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Colors per notification type — matches the HTML mockup's left-border scheme.
const _kNavy  = Color(0xFF000568);
const _kAmber = Color(0xFFFE9331);
const _kGold  = Color(0xFFD4AF37);

Color accentForType(String? type) {
  switch (type) {
    case 'BookingAccepted':
      return _kGold;
    case 'ChatMessage':
    case 'RequestIncoming':
    case 'TripStarted':
      return _kAmber;
    default:
      return _kNavy;
  }
}

class _BannerPayload {
  final String title;
  final String body;
  final String? notificationType;
  final VoidCallback? onTap;
  final Duration displayDuration;

  const _BannerPayload({
    required this.title,
    required this.body,
    this.notificationType,
    this.onTap,
    this.displayDuration = const Duration(seconds: 5),
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BannerPayload &&
          title == other.title &&
          body == other.body &&
          notificationType == other.notificationType;

  @override
  int get hashCode => Object.hash(title, body, notificationType);
}

/// Shows in-app notification banners that slide down from the top,
/// matching the RAFIQ notification card design.
///
/// Mount [InAppBannerHost] high in the widget tree (e.g., in
/// `MaterialApp.router`'s `builder`) to enable banners app-wide.
/// Then call [InAppNotificationBanner.show] from anywhere — services,
/// cubits, isolate callbacks — with no BuildContext needed.
class InAppNotificationBanner {
  static final ValueNotifier<_BannerPayload?> _notifier = ValueNotifier(null);

  /// Shows a banner. Safe to call from any isolate context, any phase,
  /// even before the navigator is mounted.
  ///
  /// [overlayState] is accepted for call-site compatibility but ignored —
  /// [InAppBannerHost] in the widget tree handles rendering.
  static void show({
    // ignore: avoid_unused_constructor_parameters
    OverlayState? overlayState,
    required String title,
    required String body,
    String? notificationType,
    VoidCallback? onTap,
    Duration displayDuration = const Duration(seconds: 5),
  }) {
    _notifier.value = _BannerPayload(
      title: title,
      body: body,
      notificationType: notificationType,
      onTap: onTap,
      displayDuration: displayDuration,
    );
  }

  static void _clear() => _notifier.value = null;
}

/// Mount this widget in [MaterialApp.router]'s `builder` so banners always
/// render within a valid widget context (no overlay null race condition).
class InAppBannerHost extends StatelessWidget {
  final Widget child;
  const InAppBannerHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_BannerPayload?>(
      valueListenable: InAppNotificationBanner._notifier,
      builder: (context, payload, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (payload != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _BannerWidget(
                  key: ValueKey(payload),
                  title: payload.title,
                  body: payload.body,
                  accentColor: accentForType(payload.notificationType),
                  displayDuration: payload.displayDuration,
                  onTap: () {
                    InAppNotificationBanner._clear();
                    payload.onTap?.call();
                  },
                  onDismissed: InAppNotificationBanner._clear,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final Color accentColor;
  final Duration displayDuration;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _BannerWidget({
    super.key,
    required this.title,
    required this.body,
    required this.accentColor,
    required this.displayDuration,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  State<_BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<_BannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)),
    );
    // Defer forward() to after the first layout so SlideTransition's
    // RenderFractionalTranslation is fully laid out before the first tick.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
    _timer = Timer(widget.displayDuration, _animateOut);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _animateOut() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _timer?.cancel();
    await _ctrl.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          child: _BannerCard(
            title: widget.title,
            body: widget.body,
            accentColor: widget.accentColor,
            onTap: widget.onTap,
            onDismiss: _animateOut,
          ),
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final String title;
  final String body;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _BannerCard({
    required this.title,
    required this.body,
    required this.accentColor,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000568).withValues(alpha: 0.10),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: accentColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.explore_rounded,
                              size: 15,
                              color: accentColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'RAFIQ',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: const Color(0xFF000568),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onDismiss();
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFF9E9FAD),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000568),
                            height: 1.3,
                          ),
                        ),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF6B6B80),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
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
