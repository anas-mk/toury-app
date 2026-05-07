import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../data/services/user_chat_signalr_service.dart';
import '../cubit/user_chat_cubit.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/user_chat_quick_replies_sheet.dart';

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
  }

  Future<void> _init() async {
    final user = await sl<AuthLocalDataSource>().getCurrentUser();
    if (user?.token != null) {
      _cubit.init(widget.bookingId, user!.token!);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.82) {
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
    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        resizeToAvoidBottomInset: true,
        appBar: _UserChatAppBar(
          fallbackName: widget.helperName,
          fallbackAvatar: widget.helperImage,
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<UserChatCubit, UserChatState>(
                builder: (context, state) {
                  if (state is UserChatLoading) {
                    return const Center(child: AppLoading(fullScreen: false));
                  }
                  if (state is UserChatLoaded) {
                    return _buildMessageList(context, state);
                  }
                  if (state is UserChatError) {
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
              onSend: _cubit.sendMessage,
              onQuickReply: () {
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => UserChatQuickRepliesSheet(onReply: _cubit.sendMessage),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, UserChatLoaded state) {
    if (state.messages.isEmpty) {
      return _buildEmptyState(context, state);
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      physics: const AlwaysScrollableScrollPhysics(),
      addAutomaticKeepAlives: false,
      itemCount: state.messages.length + (state.hasReachedMax ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == state.messages.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: AppSpinner.large()),
          );
        }

        final message = state.messages[index];
        final isMe = message.senderType.toLowerCase() == 'user';

        return ChatMessageBubble(
          key: ValueKey(message.id),
          message: message,
          isMe: isMe,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, UserChatLoaded state) {
    final h = MediaQuery.sizeOf(context).height;
    return ListView(
      reverse: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageGutter,
        vertical: AppSpacing.xl,
      ),
      children: [
        SizedBox(height: h * 0.22),
        AppEmptyState(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'No messages yet',
          message: 'Start a conversation with ${state.conversation.helper.name}',
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

/// App bar mirrored from helper chat UX; resolves helper avatar via API base.
class _UserChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? fallbackName;
  final String? fallbackAvatar;

  const _UserChatAppBar({
    required this.fallbackName,
    required this.fallbackAvatar,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
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
      title: BlocBuilder<UserChatCubit, UserChatState>(
        builder: (context, state) {
          final name = (state is UserChatLoaded)
              ? state.conversation.helper.name
              : (fallbackName ?? 'Chat');
          final imageUrl = (state is UserChatLoaded)
              ? state.conversation.helper.profileImageUrl
              : (fallbackAvatar ?? '');

          return Row(
            children: [
              CircleAvatar(
                radius: AppSize.avatarMd / 2,
                backgroundImage: imageUrl.isNotEmpty
                    ? NetworkImage(ApiConfig.resolveImageUrl(imageUrl))
                    : null,
                backgroundColor: palette.primarySoft,
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
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (state is UserChatLoaded)
                      _UserConnectionChip(state.connectionState),
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

class _UserConnectionChip extends StatelessWidget {
  final UserChatSignalRState connectionState;

  const _UserConnectionChip(this.connectionState);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    late final String label;
    late final Color indicator;

    switch (connectionState) {
      case UserChatSignalRState.connected:
        label = 'Online';
        indicator = palette.success;
        break;
      case UserChatSignalRState.connecting:
        label = 'Connecting...';
        indicator = palette.warning;
        break;
      case UserChatSignalRState.disconnected:
      case UserChatSignalRState.error:
        label = 'Offline';
        indicator = palette.textMuted;
        break;
    }

    return Row(
      children: [
        Container(
          width: AppSpacing.xs + AppSpacing.xxs,
          height: AppSpacing.xs + AppSpacing.xxs,
          decoration: BoxDecoration(color: indicator, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: indicator,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
