import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../tourist/features/user_booking/domain/entities/message_entity.dart';

class HelperMessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;

  const HelperMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : theme.textTheme.bodyLarge?.color,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: TextStyle(
                    color: (isMe ? Colors.white : theme.textTheme.bodySmall?.color)?.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  if (message.isSending)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                    )
                  else if (message.isFailed)
                    const Icon(Icons.error_outline, size: 14, color: Colors.red)
                  else
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isRead ? Colors.lightBlueAccent : Colors.white70,
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
