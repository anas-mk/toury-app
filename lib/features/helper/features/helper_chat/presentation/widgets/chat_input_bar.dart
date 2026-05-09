import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';

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
    final palette = AppColors.of(context);

    return Material(
      color: palette.surfaceElevated,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: palette.primarySoft,
                  foregroundColor: palette.primary,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: widget.onQuickReply,
                icon: const Icon(Icons.bolt_rounded, size: 22),
                tooltip: 'Quick replies',
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textPrimary,
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: palette.surfaceInset,
                    hintText: 'Message…',
                    hintStyle: TextStyle(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedSwitcher(
                duration: AppDurations.fast,
                child: _hasText
                    ? FilledButton(
                        key: const ValueKey('send'),
                        onPressed: _send,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          maximumSize: const Size(48, 48),
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                          backgroundColor: palette.primary,
                          foregroundColor: palette.onPrimary,
                        ),
                        child: const Icon(Icons.send_rounded, size: 22),
                      )
                    : SizedBox(
                        key: const ValueKey('placeholder'),
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.send_rounded,
                          color: palette.disabledText.withValues(alpha: 0.35),
                          size: 22,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
