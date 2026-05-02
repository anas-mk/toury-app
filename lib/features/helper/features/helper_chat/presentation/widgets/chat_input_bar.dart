import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_color.dart';

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
      child: SafeArea(
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
                  color: isDark ? theme.cardColor : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(28),
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
      ),
    );
  }
}
