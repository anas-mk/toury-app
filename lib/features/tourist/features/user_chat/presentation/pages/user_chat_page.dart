import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../cubit/user_chat_cubit.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../../data/services/user_chat_signalr_service.dart';

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
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
    final theme = Theme.of(context);
    
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<UserChatCubit, UserChatState>(
                builder: (context, state) {
                  if (state is UserChatLoading) {
                    return _buildLoading();
                  } else if (state is UserChatLoaded) {
                    return _buildMessageList(state);
                  } else if (state is UserChatError) {
                    return _buildError(state.message);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: BlocBuilder<UserChatCubit, UserChatState>(
        builder: (context, state) {
          final String name = (state is UserChatLoaded) ? state.conversation.helper.name : (widget.helperName ?? 'Chat');
          final String imageUrl = (state is UserChatLoaded) ? state.conversation.helper.profileImageUrl : (widget.helperImage ?? '');
          
          return Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                backgroundColor: AppColor.primaryColor.withOpacity(0.1),
                child: imageUrl.isEmpty && name != 'Chat'
                    ? Text(name[0].toUpperCase(), style: const TextStyle(color: AppColor.primaryColor, fontSize: 14))
                    : (imageUrl.isEmpty ? const Icon(Icons.person, size: 20, color: AppColor.primaryColor) : null),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (state is UserChatLoaded)
                      _buildConnectionStatus(context, state.connectionState),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context, UserChatSignalRState state) {
    final theme = Theme.of(context);
    String text = '';
    Color color = theme.colorScheme.onSurface.withOpacity(0.4);
    
    switch (state) {
      case UserChatSignalRState.connected:
        text = 'Online';
        color = const Color(0xFF00C896);
        break;
      case UserChatSignalRState.connecting:
        text = 'Connecting...';
        color = Colors.amber;
        break;
      case UserChatSignalRState.disconnected:
      case UserChatSignalRState.error:
        text = 'Offline';
        color = theme.colorScheme.onSurface.withOpacity(0.3);
        break;
    }
    
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMessageList(UserChatLoaded state) {
    if (state.messages.isEmpty) {
      return _buildEmptyState(state);
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      itemCount: state.messages.length + (state.hasReachedMax ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == state.messages.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final message = state.messages[index];
        final isMe = message.senderType.toLowerCase() == 'user';
        
        return ChatMessageBubble(
          message: message,
          isMe: isMe,
        );
      },
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColor.errorColor, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _init,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(UserChatLoaded state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, color: Theme.of(context).dividerColor, size: 64),
          const SizedBox(height: 16),
          Text(
            'Start a conversation with ${state.conversation.helper.name}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return ChatInputBar(
      onSend: (text) => _cubit.sendMessage(text),
    );
  }
}
