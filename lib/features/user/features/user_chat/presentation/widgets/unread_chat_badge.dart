import 'package:flutter/material.dart';

import '../../../../../../core/theme/brand_tokens.dart';
import '../unread_chat_tracker.dart';

/// Small red dot / count chip overlaid on top of a chat icon. Wraps
/// any child widget — typically the chat button on the live track
/// or booking confirmed pages.
///
/// Listens to [UnreadChatTracker.unreadStreamFor] so the badge
/// updates the moment a `ChatMessage` event lands on the SignalR
/// stream, without the host page having to know anything.
///
/// Usage:
/// ```dart
/// UnreadChatBadge(
///   bookingId: booking.bookingId,
///   child: IconButton(icon: Icons.chat, onPressed: ...),
/// )
/// ```
class UnreadChatBadge extends StatelessWidget {
  final String bookingId;
  final Widget child;

  /// Pixel offset of the badge from the top-right corner of [child].
  /// Tweak per icon size — `Offset(2, -2)` works for a 24 px icon
  /// inside a 48 px IconButton, `Offset(0, 0)` for a tighter pill.
  final Offset offset;

  /// Size of the dot when there's no number to show. The number
  /// chip auto-grows from this baseline.
  final double dotSize;

  const UnreadChatBadge({
    super.key,
    required this.bookingId,
    required this.child,
    this.offset = const Offset(0, 0),
    this.dotSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: UnreadChatTracker.instance.unreadStreamFor(bookingId),
      initialData: UnreadChatTracker.instance.countFor(bookingId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        final label = formatBadgeCount(count);
        if (label == null) return child;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -offset.dx,
              top: offset.dy,
              child: _Badge(label: label, dotSize: dotSize),
            ),
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final double dotSize;

  const _Badge({required this.label, required this.dotSize});

  @override
  Widget build(BuildContext context) {
    // Single-character labels render as a tight circle so the badge
    // looks like a notification dot. "9+" shows as a pill.
    final isSingleChar = label.length == 1;
    return Container(
      constraints: BoxConstraints(
        minWidth: dotSize + 8,
        minHeight: dotSize + 8,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSingleChar ? 0 : 5,
        vertical: 0,
      ),
      decoration: BoxDecoration(
        color: BrandTokens.dangerRed,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: BrandTokens.dangerRed.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          height: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
