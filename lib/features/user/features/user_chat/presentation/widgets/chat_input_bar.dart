import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String) onSend;

  const ChatInputBar({super.key, required this.onSend});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _canSend = _controller.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_canSend) {
      widget.onSend(_controller.text.trim());
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: palette.scaffold,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: palette.textMuted),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: AppDurations.fast,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _canSend ? palette.primary : palette.disabledFill,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Send message',
              onPressed: _canSend ? _handleSend : null,
              icon: Icon(
                Icons.send_rounded,
                color: _canSend ? Colors.white : palette.disabledText,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
