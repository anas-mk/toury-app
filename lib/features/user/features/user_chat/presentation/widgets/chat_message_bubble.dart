import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/user_chat_entities.dart';

/// Chat message bubble — editorial mockup styling.
///
///   • Helper (left): white card, soft warm border, square-bottom-left
///     corner, optional avatar tucked at the bottom-left.
///   • User (right): deep-navy filled pill, square-bottom-right corner,
///     timestamp + read receipt rendered BELOW the bubble (not inside).
///
/// Avatar is shown only on the first / last bubble of a streak so the
/// thread doesn't look noisy. If the parent doesn't pass a value
/// (default `true`) we render it unconditionally for safety.
class ChatMessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isMe;

  /// URL of the helper's profile image — only used for left-side
  /// bubbles. Null falls back to a placeholder circle.
  final String? helperImageUrl;

  /// `true` when this bubble should render the avatar (typically the
  /// last bubble of a sender streak). Avatars are skipped on
  /// successive helper messages so the thread reads cleaner.
  final bool showAvatar;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.helperImageUrl,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: isMe ? _userBubble(context) : _helperBubble(context),
        ),
      ),
    );
  }

  Widget _helperBubble(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: showAvatar
              ? Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE8E4DF)),
                  ),
                  child: ClipOval(
                    child: AppNetworkImage(
                      imageUrl: helperImageUrl,
                      width: 30,
                      height: 30,
                      borderRadius: 15,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE8E4DF)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F1B237E),
                  blurRadius: 30,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              message.text.isEmpty ? '…' : message.text,
              style: const TextStyle(
                color: Color(0xFF1B1B21),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _userBubble(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: BrandTokens.primaryBlue,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(99),
              topRight: Radius.circular(99),
              bottomLeft: Radius.circular(99),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.20),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            message.text.isEmpty ? '…' : message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        // Timestamp + read receipt row, sitting below the bubble like
        // in the mockup (not crammed inside).
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('h:mm a').format(message.sentAt.toLocal()),
                style: const TextStyle(
                  color: Color(0xFF767683),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                message.isPending
                    ? Icons.access_time_rounded
                    : (message.isRead
                        ? Icons.done_all_rounded
                        : Icons.done_rounded),
                size: 16,
                color: message.isRead
                    ? BrandTokens.primaryBlue
                    : const Color(0xFF767683),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
