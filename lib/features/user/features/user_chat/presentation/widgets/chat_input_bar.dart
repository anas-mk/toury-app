import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/theme/brand_tokens.dart';

/// Editorial chat input pill — single rounded white pill containing:
///   • An "add" leading icon (placeholder for future attachments).
///   • The text field.
///   • A primary blue circular send button.
///
/// Sits on a soft warm-off-white gradient that fades into the body
/// behind so the messages list peeks through when the user scrolls.
class ChatInputBar extends StatefulWidget {
  final void Function(String) onSend;
  final String? hintText;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.hintText,
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
      final next = _controller.text.trim().isNotEmpty;
      if (next != _canSend) {
        setState(() => _canSend = next);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (!_canSend) return;
    HapticFeedback.selectionClick();
    widget.onSend(_controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xFFFAF8F4),
            Color(0xE6FAF8F4),
            Color(0x00FAF8F4),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFE8E4DF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F1B237E),
                  blurRadius: 30,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
            child: Row(
              children: [
                IconButton(
                  // Placeholder for attachments. Wired to a snackbar
                  // for now; can be replaced with a sheet later.
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Attachments coming soon'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Color(0xFF767683),
                    size: 24,
                  ),
                  splashRadius: 22,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      color: Color(0xFF1B1B21),
                      fontSize: 16,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText ?? 'Type a message…',
                      hintStyle: const TextStyle(
                        color: Color(0xFF767683),
                        fontSize: 16,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _handleSend(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedScale(
                  scale: _canSend ? 1.0 : 0.92,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _canSend ? 1.0 : 0.5,
                    child: Material(
                      color: BrandTokens.primaryBlue,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _canSend ? _handleSend : null,
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
