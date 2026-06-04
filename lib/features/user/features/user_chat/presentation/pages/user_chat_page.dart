import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../data/services/user_chat_signalr_service.dart';
import '../../domain/entities/user_chat_entities.dart';
import '../cubit/user_chat_cubit.dart';
import '../unread_chat_tracker.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';

/// Pass #6 — editorial chat redesign.
///
/// Layout:
///   • Warm cream background (`#FAF8F4`).
///   • Top bar: back pill + avatar w/ live status dot + name +
///     "In Trip" subtitle.
///   • Context bar: location chip + collapsible (placeholder).
///   • Message canvas: helper bubbles (white card, square bottom-left)
///     and user bubbles (deep navy pill, square bottom-right) with
///     timestamps + read receipts.
///   • Input pill: rounded white pill with `+` leading icon, multi-
///     line text field, and primary send button.
///
/// Realtime fixes (separately wired):
///   • The SignalR service now subscribes to `ChatMessage` (matching
///     the backend wire format) instead of the old non-existent
///     `ReceiveChatMessage`.
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
  late final UserChatCubit _cubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = sl<UserChatCubit>();
    _init();
    _scrollController.addListener(_onScroll);
    // Tell the global unread tracker that we're now reading this
    // booking's chat — incoming messages while the page is open
    // should never show a badge.
    UnreadChatTracker.instance.setActive(widget.bookingId);
  }

  Future<void> _init() async {
    final user = await sl<AuthLocalDataSource>().getCurrentUser();
    if (user?.token != null) {
      _cubit.init(widget.bookingId, user!.token!);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _cubit.loadMore();
    }
  }

  @override
  void dispose() {
    UnreadChatTracker.instance.setInactive(widget.bookingId);
    _cubit.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFFAF8F4),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _ChatTopBar(
                  fallbackName: widget.helperName,
                  fallbackImage: widget.helperImage,
                ),
                _ContextBar(),
                Expanded(
                  child: BlocBuilder<UserChatCubit, UserChatState>(
                    builder: (context, state) {
                      if (state is UserChatLoading ||
                          state is UserChatInitial) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: BrandTokens.primaryBlue,
                            strokeWidth: 2.4,
                          ),
                        );
                      }
                      if (state is UserChatLoaded) {
                        if (state.messages.isEmpty) {
                          return _EmptyState(state: state);
                        }
                        return _buildMessageList(state);
                      }
                      if (state is UserChatError) {
                        return _ErrorBlock(
                          message: state.message,
                          onRetry: _init,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                ChatInputBar(
                  hintText: 'Message ${widget.helperName ?? 'helper'}…',
                  onSend: (text) => _cubit.sendMessage(text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(UserChatLoaded state) {
    final msgs = state.messages;
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
      itemCount: msgs.length + (state.hasReachedMax ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == msgs.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: BrandTokens.primaryBlue,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        // The list is rendered with `reverse: true`, so index 0 is
        // the newest message (bottom of the screen). To draw a
        // day-separator chip whenever the day boundary changes we
        // peek at the message that comes BEFORE this one in chrono
        // order, which in the reversed list is the next index up.
        final msg = msgs[index];
        final older = (index + 1 < msgs.length) ? msgs[index + 1] : null;
        final showDay = _showDaySeparator(msg, older);

        // Avatar streak suppression: only show the helper avatar on
        // the LAST bubble in a streak of consecutive helper messages
        // (i.e. the one whose previous reversed-list neighbour comes
        // from the user, or the very last visible item).
        final newer = index > 0 ? msgs[index - 1] : null;
        final showAvatar = _showAvatarOnHelperBubble(msg, newer);

        final isMe = msg.senderType.toLowerCase() == 'user';

        return Column(
          children: [
            if (showDay)
              _DaySeparator(date: msg.sentAt.toLocal()),
            ChatMessageBubble(
              message: msg,
              isMe: isMe,
              helperImageUrl: state.conversation.helper.profileImageUrl,
              showAvatar: showAvatar,
            ),
          ],
        );
      },
    );
  }

  bool _showDaySeparator(
    ChatMessageEntity current,
    ChatMessageEntity? older,
  ) {
    if (older == null) return true;
    final a = current.sentAt.toLocal();
    final b = older.sentAt.toLocal();
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }

  bool _showAvatarOnHelperBubble(
    ChatMessageEntity current,
    ChatMessageEntity? newer,
  ) {
    final isMe = current.senderType.toLowerCase() == 'user';
    if (isMe) return false;
    if (newer == null) return true;
    return newer.senderType.toLowerCase() == 'user';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _ChatTopBar extends StatelessWidget {
  final String? fallbackName;
  final String? fallbackImage;

  const _ChatTopBar({
    required this.fallbackName,
    required this.fallbackImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBF8FF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8E4DF)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: BlocBuilder<UserChatCubit, UserChatState>(
        builder: (context, state) {
          final String name = state is UserChatLoaded
              ? state.conversation.helper.name
              : (fallbackName ?? 'Chat');
          final String imageUrl = state is UserChatLoaded
              ? state.conversation.helper.profileImageUrl
              : (fallbackImage ?? '');
          final UserChatSignalRState? conn =
              state is UserChatLoaded ? state.connectionState : null;

          return Row(
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_rounded),
                color: BrandTokens.primaryBlue,
                splashRadius: 22,
              ),
              const SizedBox(width: 4),
              // Avatar with status dot.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE8E4DF)),
                    ),
                    child: ClipOval(
                      child: AppNetworkImage(
                        imageUrl: imageUrl.isEmpty ? null : imageUrl,
                        width: 38,
                        height: 38,
                        borderRadius: 19,
                      ),
                    ),
                  ),
                  if (conn == UserChatSignalRState.connected)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFBF8FF),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1B1B21),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _ConnectionStatusLine(state: conn),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  // Placeholder for the kebab menu (mute / report /
                  // helper profile shortcut). Wired to a snackbar
                  // until the menu is built.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat options coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.more_vert_rounded),
                color: BrandTokens.primaryBlue,
                splashRadius: 22,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConnectionStatusLine extends StatelessWidget {
  final UserChatSignalRState? state;
  const _ConnectionStatusLine({required this.state});

  @override
  Widget build(BuildContext context) {
    String text;
    switch (state) {
      case UserChatSignalRState.connected:
        text = 'In Trip';
        break;
      case UserChatSignalRState.connecting:
        text = 'Connecting…';
        break;
      case UserChatSignalRState.disconnected:
      case UserChatSignalRState.error:
        text = 'Offline';
        break;
      case null:
        text = 'In Trip';
        break;
    }
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF767683),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Context bar
// ─────────────────────────────────────────────────────────────────────────────

class _ContextBar extends StatelessWidget {
  String _formatBookingDate(DateTime? when) {
    if (when == null) return '';
    final local = when.toLocal();
    return DateFormat('MMM d').format(local);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserChatCubit, UserChatState>(
      builder: (context, state) {
        String? destination;
        DateTime? when;
        if (state is UserChatLoaded) {
          // The conversation itself doesn't carry a destination; the
          // booking detail page does. We fall back to the booking id
          // suffix as a last resort so the bar is never empty.
          destination = null;
          when = state.conversation.lastMessageAt ??
              state.conversation.activatedAt ??
              state.conversation.createdAt;
        }
        final left = [
          if (destination != null && destination.isNotEmpty) destination,
          if (when != null) _formatBookingDate(when),
        ].where((s) => s.isNotEmpty).join(' · ');

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE8E4DF)),
            ),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF767683),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  left.isEmpty ? 'Trip in progress' : left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF464652),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: Color(0xFF767683),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day separator pill
// ─────────────────────────────────────────────────────────────────────────────

class _DaySeparator extends StatelessWidget {
  final DateTime date;
  const _DaySeparator({required this.date});

  String _label(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today, ${DateFormat('h:mm a').format(date)}';
    if (d == yesterday) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8F4),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFFE8E4DF)),
          ),
          child: Text(
            _label(context),
            style: const TextStyle(
              color: Color(0xFF767683),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty + error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final UserChatLoaded state;
  const _EmptyState({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: BrandTokens.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Say hi to ${state.conversation.helper.name}',
              textAlign: TextAlign.center,
              style: BrandTokens.heading(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: BrandTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share pickup notes, ask for directions, or just '
              'introduce yourself.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF464652),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: BrandTokens.dangerRed,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF464652),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
