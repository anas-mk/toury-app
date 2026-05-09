import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../domain/entities/helper_chat_entities.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isMe;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final bubbleMaxW = MediaQuery.sizeOf(context).width * 0.78;
    final radius = AppRadius.xl;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageGutter,
        vertical: AppSpacing.xs,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radius),
                  topRight: Radius.circular(radius),
                  bottomLeft: Radius.circular(isMe ? radius : AppRadius.xs),
                  bottomRight: Radius.circular(isMe ? AppRadius.xs : radius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? palette.primary : palette.textPrimary)
                        .withValues(alpha: palette.isDark ? 0.12 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Container(
                constraints: BoxConstraints(maxWidth: bubbleMaxW),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md + AppSpacing.xs,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: isMe ? palette.primary : palette.surfaceElevated,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    topRight: Radius.circular(radius),
                    bottomLeft: Radius.circular(isMe ? radius : AppRadius.xs),
                    bottomRight: Radius.circular(isMe ? AppRadius.xs : radius),
                  ),
                  border: Border.all(
                    color: isMe
                        ? Colors.transparent
                        : palette.border.withValues(alpha: 0.55),
                    width: AppSize.hairline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isMe ? Colors.white : palette.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.sentAt.toLocal()),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isMe ? Colors.white70 : palette.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: AppSpacing.xs),
                          if (message.isPending)
                            const AppSpinner(
                              size: 11,
                              strokeWidth: 1.2,
                              color: Colors.white70,
                            )
                          else if (message.isFailed)
                            Icon(
                              Icons.error_outline_rounded,
                              size: 14,
                              color: palette.danger,
                            )
                          else
                            Icon(
                              message.isRead
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 15,
                              color: message.isRead
                                  ? palette.success
                                  : Colors.white54,
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
