import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/chat_entities.dart';
import '../cubit/user_chat_cubit.dart';
import '../cubit/user_chat_state.dart';
import '../widgets/chat_message_bubble.dart';

/// Pass #5 redesign — modern, fast chat surface for the tourist side.
///
/// Layout:
///   • Frosted glass app bar with avatar + status dot
///   • Day-grouped message list (auto-scroll on new)
///   • Empty / loading / error states
///   • Composer with rounded glass field and gradient send button
class UserChatPage extends StatefulWidget {
  final String bookingId;
  final String? helperName;
  final String? helperImage;

  const UserChatPage({
    super.key,
    required this.bookingId,
    this.helperName,
    this.helperImage,
  });

  @override
  State<UserChatPage> createState() => _UserChatPageState();
}

class _UserChatPageState extends State<UserChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late final UserChatCubit _cubit;

  /// Notifier (instead of `setState`) so a keystroke only rebuilds the
  /// send button — not the BlocBuilder + message list above the
  /// composer. This kept frame times sub-16ms while typing.
  final ValueNotifier<bool> _hasText = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _cubit = sl<UserChatCubit>()..loadMessages(widget.bookingId);
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = _messageController.text.trim().isNotEmpty;
    if (has != _hasText.value) _hasText.value = has;
  }

  void _send() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    _cubit.sendMessage(widget.bookingId, text);
    _messageController.clear();
    _hasText.value = false;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _hasText.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: BrandTokens.bgSoft,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<UserChatCubit, UserChatState>(
                  builder: (context, state) {
                    if (state is ChatLoading || state is UserChatInitial) {
                      return const _ChatSkeleton();
                    }
                    if (state is ChatLoaded) {
                      if (state.messages.isEmpty) {
                        return _EmptyChat(helperName: widget.helperName);
                      }
                      return _MessagesList(
                        messages: state.messages,
                        scrollController: _scrollController,
                      );
                    }
                    if (state is ChatError) {
                      return _ErrorState(
                        message: state.message,
                        onRetry: () =>
                            _cubit.loadMessages(widget.bookingId),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              _Composer(
                controller: _messageController,
                focusNode: _focusNode,
                hasText: _hasText,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final r = Responsive.of(context);
    return PreferredSize(
      preferredSize: Size.fromHeight(r.viewPadding.top + 64),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: BrandTokens.surfaceWhite.withValues(alpha: 0.85),
              border: Border(
                bottom: BorderSide(
                  color: BrandTokens.borderSoft.withValues(alpha: 0.7),
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: r.pagePadding,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    SizedBox(width: r.gapSM),
                    _AvatarWithStatus(
                      imageUrl: widget.helperImage,
                      online: true,
                    ),
                    SizedBox(width: r.gapSM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.helperName ?? 'Your helper',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BrandTokens.heading(
                              fontSize: r.fontBody + 2,
                              fontWeight: FontWeight.w800,
                              color: BrandTokens.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: BrandTokens.successGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Online',
                                style: BrandTokens.body(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: BrandTokens.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _RoundIconButton(
                      icon: Icons.call_outlined,
                      onTap: () {
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandTokens.bgSoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: BrandTokens.textPrimary),
        ),
      ),
    );
  }
}

class _AvatarWithStatus extends StatelessWidget {
  final String? imageUrl;
  final bool online;
  const _AvatarWithStatus({required this.imageUrl, required this.online});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  BrandTokens.successGreen,
                  BrandTokens.primaryBlue,
                ],
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: AppNetworkImage(
                imageUrl: imageUrl,
                width: 40,
                height: 40,
                borderRadius: 20,
              ),
            ),
          ),
          if (online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: BrandTokens.successGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                         MESSAGES LIST
// ─────────────────────────────────────────────────────────────────────────────
class _MessagesList extends StatelessWidget {
  final List<ChatMessageEntity> messages;
  final ScrollController scrollController;

  const _MessagesList({
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    // Build "items" — the input is reverse-chronological (newest first)
    // because the ListView is `reverse: true`. We walk forward inserting
    // day separators where consecutive items cross a date boundary.
    final items = <_ListItem>[];
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final next = i + 1 < messages.length ? messages[i + 1] : null;
      // Decide tail: hide if next message is from same sender and within 2 minutes.
      final groupWithNext = next != null &&
          next.senderType == m.senderType &&
          m.sentAt.difference(next.sentAt).inMinutes < 2;
      items.add(_ListItem.message(m, showTail: !groupWithNext));

      // For day separators, look at previous (older) message — since we
      // render reversed, that's index i+1. Insert separator on transition.
      final mLocal = m.sentAt.toLocal();
      final olderLocal = next?.sentAt.toLocal();
      if (olderLocal != null) {
        if (mLocal.year != olderLocal.year ||
            mLocal.month != olderLocal.month ||
            mLocal.day != olderLocal.day) {
          items.add(_ListItem.day(mLocal));
        }
      } else {
        items.add(_ListItem.day(mLocal));
      }
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: EdgeInsets.fromLTRB(
        r.pagePadding,
        r.gapSM,
        r.pagePadding,
        MediaQuery.of(context).viewPadding.top + 80,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isDay) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: r.gapSM),
            child: _DaySeparator(date: item.date!),
          );
        }
        final m = item.message!;
        return ChatMessageBubble(
          message: m,
          isMe: m.senderType == 'User',
          showTail: item.showTail,
        );
      },
    );
  }
}

class _ListItem {
  final ChatMessageEntity? message;
  final bool showTail;
  final DateTime? date;

  _ListItem.message(this.message, {required this.showTail}) : date = null;
  _ListItem.day(DateTime d)
      : message = null,
        showTail = false,
        date = d;

  bool get isDay => date != null;
}

class _DaySeparator extends StatelessWidget {
  final DateTime date;
  const _DaySeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: BrandTokens.surfaceWhite,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: BrandTokens.borderSoft.withValues(alpha: 0.7),
          ),
        ),
        child: Text(
          _formatDay(date),
          style: BrandTokens.body(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: BrandTokens.textSecondary,
          ),
        ),
      ),
    );
  }

  static String _formatDay(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${that.day}/${that.month}/${that.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                         COMPOSER
// ─────────────────────────────────────────────────────────────────────────────
class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueListenable<bool> hasText;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Container(
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        border: Border(
          top: BorderSide(
            color: BrandTokens.borderSoft.withValues(alpha: 0.7),
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            r.pagePadding,
            r.gapSM,
            r.pagePadding - 4,
            r.gapSM,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 44,
                    maxHeight: 140,
                  ),
                  decoration: BoxDecoration(
                    color: BrandTokens.bgSoft,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: BrandTokens.borderSoft.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.emoji_emotions_outlined,
                        color: BrandTokens.textSecondary,
                        size: 22,
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          minLines: 1,
                          maxLines: 5,
                          style: BrandTokens.body(
                            fontSize: r.fontBody + 1,
                            color: BrandTokens.textPrimary,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Type a message…',
                            hintStyle: BrandTokens.body(
                              fontSize: r.fontBody + 1,
                              color: BrandTokens.textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.fromLTRB(
                              10,
                              12,
                              10,
                              12,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<bool>(
                valueListenable: hasText,
                builder: (context, has, _) {
                  return BlocBuilder<UserChatCubit, UserChatState>(
                    buildWhen: (a, b) {
                      final av = a is ChatLoaded && a.isSending;
                      final bv = b is ChatLoaded && b.isSending;
                      return av != bv;
                    },
                    builder: (context, state) {
                      final isSending =
                          state is ChatLoaded && state.isSending;
                      return _SendButton(
                        enabled: has && !isSending,
                        sending: isSending,
                        onTap: onSend,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final bool sending;
  final VoidCallback onTap;

  const _SendButton({
    required this.enabled,
    required this.sending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BrandTokens.successGreen,
                  BrandTokens.primaryBlue,
                ],
              )
            : null,
        color: enabled ? null : BrandTokens.borderSoft,
        shape: BoxShape.circle,
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: BrandTokens.glowBlue,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Center(
            child: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    color: enabled ? Colors.white : BrandTokens.textSecondary,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                         STATES (loading / empty / error)
// ─────────────────────────────────────────────────────────────────────────────
class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        r.pagePadding,
        r.viewPadding.top + 80,
        r.pagePadding,
        r.gap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 6; i++)
            Padding(
              padding: EdgeInsets.only(bottom: r.gapSM + 2),
              child: Align(
                alignment:
                    i.isEven ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: 200 + (i * 14).toDouble(),
                  height: 36,
                  decoration: BoxDecoration(
                    color: BrandTokens.borderSoft.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final String? helperName;
  const _EmptyChat({required this.helperName});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        r.pagePadding,
        r.viewPadding.top + 80,
        r.pagePadding,
        r.gap,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    BrandTokens.successGreen,
                    BrandTokens.primaryBlue,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: BrandTokens.glowBlue,
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            SizedBox(height: r.gap),
            Text(
              'Start the conversation',
              style: BrandTokens.heading(
                fontSize: r.fontTitle + 2,
                fontWeight: FontWeight.w800,
                color: BrandTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              helperName == null
                  ? 'Send the first message to your helper'
                  : 'Say hello to ${helperName!.split(' ').first} 👋',
              textAlign: TextAlign.center,
              style: BrandTokens.body(
                fontSize: r.fontBody,
                color: BrandTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(r.gap),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: BrandTokens.textSecondary,
            ),
            SizedBox(height: r.gapSM),
            Text(
              "Couldn't load messages",
              style: BrandTokens.heading(
                fontSize: r.fontTitle,
                fontWeight: FontWeight.w800,
                color: BrandTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: BrandTokens.body(
                fontSize: r.fontBody,
                color: BrandTokens.textSecondary,
              ),
            ),
            SizedBox(height: r.gap),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: BrandTokens.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
