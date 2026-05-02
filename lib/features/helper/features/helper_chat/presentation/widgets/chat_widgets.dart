import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../domain/entities/helper_chat_entities.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          isMe ? 60 : 16,
          4,
          isMe ? 16 : 60,
          4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe 
              ? AppColor.primaryColor 
              : (isDark ? theme.colorScheme.surface : AppColor.lightSurface),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.sentAt.toLocal()),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  if (message.isPending)
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white70),
                    )
                  else if (message.isFailed)
                    const Icon(Icons.error_outline_rounded, size: 14, color: Colors.white)
                  else
                    Icon(
                      message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 14,
                      color: message.isRead ? AppColor.accentColor : Colors.white38,
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

class ChatInputBar extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback onQuickReply;

  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.onQuickReply,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.amber),
            onPressed: widget.onQuickReply,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColor.lightBorder),
              ),
              child: TextField(
                controller: _controller,
                style: theme.textTheme.bodyMedium,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedScale(
            scale: _hasText ? 1.0 : 0.8,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _hasText ? _send : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hasText ? AppColor.primaryColor : theme.disabledColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _hasText ? Colors.white : (isDark ? Colors.white38 : Colors.black38),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickRepliesSheet extends StatelessWidget {
  final Function(String) onReply;

  const QuickRepliesSheet({super.key, required this.onReply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final replies = [
      "I'm on my way",
      "I arrived",
      "Please share exact location",
      "Running 5 minutes late",
      "Thank you",
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Replies',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...replies.map((reply) => ListTile(
                title: Text(reply, style: theme.textTheme.bodyMedium),
                onTap: () {
                  onReply(reply);
                  Navigator.pop(context);
                },
                trailing: const Icon(Icons.arrow_forward_ios, color: AppColor.lightTextSecondary, size: 14),
                contentPadding: EdgeInsets.zero,
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
