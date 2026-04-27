import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../domain/entities/chat_entities.dart';

/// Pass #5 redesign — pill-shaped chat bubble with read-receipts and
/// time inline. Out-going (me) bubbles use the brand gradient; incoming
/// bubbles are a soft surface with a thin border for legibility on
/// light backgrounds.
class ChatMessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isMe;

  /// When true, the avatar/tail are rendered for this bubble. Group
  /// consecutive messages from the same sender by passing `false` for
  /// the middle ones to keep the wall feeling like a real chat thread.
  final bool showTail;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showTail = true,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final maxBubble = r.width *
        (r.isCompact ? 0.84 : (r.isTablet ? 0.62 : 0.74));

    return Padding(
      padding: EdgeInsets.only(bottom: showTail ? r.gapSM + 2 : 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubble),
            child: _Bubble(
              message: message,
              isMe: isMe,
              showTail: showTail,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isMe;
  final bool showTail;
  const _Bubble({
    required this.message,
    required this.isMe,
    required this.showTail,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final hasTrailingTail = showTail;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.pick(compact: 12.0, phone: 14.0, tablet: 16.0),
        vertical: r.pick(compact: 8.0, phone: 10.0, tablet: 11.0),
      ),
      decoration: BoxDecoration(
        gradient: isMe
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BrandTokens.primaryBlue,
                  BrandTokens.primaryBlueDark,
                ],
              )
            : null,
        color: isMe ? null : BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : (hasTrailingTail ? 4 : 20)),
          bottomRight: Radius.circular(isMe ? (hasTrailingTail ? 4 : 20) : 20),
        ),
        border: isMe
            ? null
            : Border.all(
                color: BrandTokens.borderSoft.withValues(alpha: 0.7),
              ),
        boxShadow: isMe
            ? const [
                BoxShadow(
                  color: BrandTokens.glowBlue,
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: BrandTokens.shadowSoft.withValues(alpha: 0.6),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.text,
            style: BrandTokens.body(
              fontSize: r.fontBody + 1,
              color: isMe ? Colors.white : BrandTokens.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('jm').format(message.sentAt.toLocal()),
                style: BrandTokens.body(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.78)
                      : BrandTokens.textSecondary,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isRead
                      ? Icons.done_all_rounded
                      : Icons.done_rounded,
                  size: 13,
                  color: message.isRead
                      ? const Color(0xFF7AD3FF)
                      : Colors.white.withValues(alpha: 0.78),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
