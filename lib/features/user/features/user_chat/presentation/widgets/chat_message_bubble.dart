import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../domain/entities/user_chat_entities.dart';

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
    final bubbleMaxW = MediaQuery.sizeOf(context).width * 0.75;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: bubbleMaxW),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isMe ? palette.primary : palette.surfaceElevated,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg + 2),
                  topRight: const Radius.circular(AppRadius.lg + 2),
                  bottomLeft: Radius.circular(isMe ? AppRadius.lg + 2 : AppRadius.xs),
                  bottomRight: Radius.circular(isMe ? AppRadius.xs : AppRadius.lg + 2),
                ),
                border: Border.all(
                  width: palette.isDark ? AppSize.hairline : AppSize.border * 0.65,
                  color: isMe
                      ? Colors.transparent
                      : palette.border.withValues(alpha: 0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: palette.isDark ? 0.2 : 0.05),
                    blurRadius: AppSpacing.md + AppSpacing.sm,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMe ? Colors.white : palette.textPrimary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.sentAt.toLocal()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isMe ? Colors.white70 : palette.textMuted,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: AppSpacing.xs),
                        if (message.isPending)
                          AppSpinner(
                            size: 12,
                            strokeWidth: 1.3,
                            color: Colors.white70,
                          )
                        else
                          Icon(
                            message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                            size: AppSize.iconSm,
                            color: message.isRead ? palette.success : Colors.white54,
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
