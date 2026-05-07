import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';

class ChatInputBar extends StatefulWidget {
  final void Function(String) onSend;
  final VoidCallback? onQuickReply;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onQuickReply,
  });

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
    final quick = widget.onQuickReply;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: palette.scaffold,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (quick != null) ...[
              IconButton(
                icon: Icon(Icons.flash_on_rounded, color: palette.warning),
                tooltip: 'Quick replies',
                onPressed: quick,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surfaceInset,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: Theme.of(context).textTheme.bodyMedium,
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
            const SizedBox(width: AppSpacing.sm),
            AnimatedScale(
              scale: _canSend ? 1.0 : 0.92,
              duration: AppDurations.fast,
              child: GestureDetector(
                onTap: _canSend ? _handleSend : null,
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  width: AppSize.icon2Xl + AppSpacing.sm,
                  height: AppSize.icon2Xl + AppSpacing.sm,
                  decoration: BoxDecoration(
                    color: _canSend ? palette.primary : palette.disabledFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: _canSend ? Colors.white : palette.disabledText,
                    size: AppSize.iconMd,
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
