import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          isMe ? 60 : 16,
          4,
          isMe ? 16 : 60,
          4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6C63FF) : const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
            if (isMe)
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.sentAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: message.isRead ? const Color(0xFF00C896) : Colors.white38,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                color: const Color(0xFF1A1F3C),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white24),
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
                  color: _hasText ? const Color(0xFF6C63FF) : Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
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
    final replies = [
      "I'm on my way",
      "I arrived",
      "Please share exact location",
      "Running 5 minutes late",
      "Thank you",
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF141829),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Replies',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...replies.map((reply) => ListTile(
                title: Text(reply, style: const TextStyle(color: Colors.white70)),
                onTap: () {
                  onReply(reply);
                  Navigator.pop(context);
                },
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                contentPadding: EdgeInsets.zero,
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
