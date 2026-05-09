import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:toury/core/config/api_config.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../auth/data/datasources/helper_local_data_source.dart';
import '../cubit/helper_chat_cubit.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_widgets.dart';

class HelperChatPage extends StatefulWidget {
  final String bookingId;
  final String? userName;
  final String? userAvatar;

  const HelperChatPage({
    super.key,
    required this.bookingId,
    this.userName,
    this.userAvatar,
  });

  /// Opens booking-scoped chat (REST history + SignalR). Prefer this over ad-hoc [Navigator.push].
  static Future<void> open(
    BuildContext context, {
    required String bookingId,
    String? userName,
    String? userAvatar,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HelperChatPage(
          bookingId: bookingId,
          userName: userName,
          userAvatar: userAvatar,
        ),
      ),
    );
  }

  @override
  State<HelperChatPage> createState() => _HelperChatPageState();
}

class _HelperChatPageState extends State<HelperChatPage> {
  late final HelperChatCubit _cubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = sl<HelperChatCubit>();
    _init();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _init() async {
    final helper = await sl<HelperLocalDataSource>().getCurrentHelper();
    if (helper?.token != null) {
      _cubit.init(widget.bookingId, helper!.token!);
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
    _cubit.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        resizeToAvoidBottomInset: true,
        appBar: _HelperChatAppBar(
          fallbackName: widget.userName,
          fallbackAvatar: widget.userAvatar,
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                palette.surfaceInset.withValues(alpha: palette.isDark ? 0.35 : 0.65),
                palette.scaffold,
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<HelperChatCubit, HelperChatState>(
                  builder: (context, state) {
                    if (state is HelperChatLoading) {
                      return const Center(child: AppLoading(fullScreen: false));
                    }
                    if (state is HelperChatLoaded) {
                      return RefreshIndicator.adaptive(
                        onRefresh: () => _cubit.refresh(),
                        color: Theme.of(context).colorScheme.primary,
                        child: _buildMessageList(state),
                      );
                    }
                    if (state is HelperChatError) {
                      return AppErrorState(
                        message: state.message,
                        onRetry: _init,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              ChatInputBar(
                onSend: (text) => _cubit.sendMessage(text),
                onQuickReply: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => QuickRepliesSheet(
                      onReply: (text) => _cubit.sendMessage(text),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(HelperChatLoaded state) {
    if (state.messages.isEmpty) {
      return _buildEmptyState(context, state);
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: state.messages.length + (state.hasReachedMax ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == state.messages.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: AppSpinner.large()),
          );
        }

        final message = state.messages[index];
        final isMe = message.senderType.toLowerCase() == 'helper';

        return ChatMessageBubble(
          key: ValueKey(message.id),
          message: message,
          isMe: isMe,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, HelperChatLoaded state) {
    return ListView(
      reverse: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageGutter,
        vertical: AppSpacing.xxl,
      ),
      children: [
        const SizedBox(height: AppSpacing.giga),
        AppEmptyState(
          icon: Icons.forum_outlined,
          title: 'No messages yet',
          message:
              'Say hello to ${state.conversation.user.name} — replies sync instantly when you\'re online.',
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

/// App bar title row with traveler avatar — matches chrome of [BasicAppBar]
/// without losing connection status or dynamic name from the cubit.
class _HelperChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? fallbackName;
  final String? fallbackAvatar;

  const _HelperChatAppBar({
    required this.fallbackName,
    required this.fallbackAvatar,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: palette.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: palette.border.withValues(alpha: 0.45),
        ),
      ),
      leading: canPop
          ? IconButton(
              splashRadius: 20,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: palette.textPrimary,
                size: AppSize.iconMd,
              ),
              onPressed: () => Navigator.maybePop(context),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          : null,
      titleSpacing: AppSpacing.sm,
      title: BlocBuilder<HelperChatCubit, HelperChatState>(
        builder: (context, state) {
          final name = (state is HelperChatLoaded)
              ? state.conversation.user.name
              : (fallbackName ?? 'Chat');
          final imageUrl = (state is HelperChatLoaded)
              ? state.conversation.user.profileImageUrl
              : (fallbackAvatar ?? '');

          return Row(
            children: [
              CircleAvatar(
                radius: AppSize.avatarMd / 2,
                backgroundColor: palette.primarySoft,
                backgroundImage: imageUrl.isNotEmpty
                    ? NetworkImage(ApiConfig.resolveImageUrl(imageUrl))
                    : null,
                child: imageUrl.isEmpty && name != 'Chat'
                    ? Text(
                        name[0].toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : (imageUrl.isEmpty
                          ? Icon(
                              Icons.person_rounded,
                              size: AppSize.iconMd,
                              color: palette.primary,
                            )
                          : null),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: palette.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (state is HelperChatLoaded)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: _ConnectionStatusChip(state.connectionState),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConnectionStatusChip extends StatelessWidget {
  final HubConnectionState connectionState;

  const _ConnectionStatusChip(this.connectionState);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    late final String label;
    late final Color indicator;

    switch (connectionState) {
      case HubConnectionState.Connected:
        label = 'Online';
        indicator = palette.success;
        break;
      case HubConnectionState.Connecting:
      case HubConnectionState.Reconnecting:
        label = 'Connecting...';
        indicator = palette.warning;
        break;
      case HubConnectionState.Disconnected:
      case HubConnectionState.Disconnecting:
        label = 'Offline';
        indicator = palette.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: indicator.withValues(alpha: palette.isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: indicator, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: indicator,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
