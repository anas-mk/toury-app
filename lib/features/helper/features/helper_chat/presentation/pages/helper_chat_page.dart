import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/features/helper/features/helper_chat/data/services/helper_chat_signalr_service.dart';
import 'package:toury/core/config/api_config.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../auth/data/datasources/helper_local_data_source.dart';
import '../cubit/helper_chat_cubit.dart';
import '../widgets/chat_widgets.dart';

class HelperChatPage extends StatefulWidget {
  final String bookingId;

  const HelperChatPage({super.key, required this.bookingId});

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
              child: BlocBuilder<HelperChatCubit, HelperChatState>(
                builder: (context, state) {
                  if (state is HelperChatLoading) {
                    return _buildLoading();
                  } else if (state is HelperChatLoaded) {
                    return _buildMessageList(state);
                  } else if (state is HelperChatError) {
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: BlocBuilder<HelperChatCubit, HelperChatState>(
        builder: (context, state) {
          if (state is HelperChatLoaded) {
            final user = state.conversation.user;
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: user.profileImageUrl.isNotEmpty 
                      ? NetworkImage(ApiConfig.resolveImageUrl(user.profileImageUrl)) 
                      : null,
                  backgroundColor: BrandTokens.primaryBlue.withValues(alpha: 0.1),
                  child: user.profileImageUrl.isEmpty
                      ? Text(user.name[0], style: const TextStyle(color: BrandTokens.primaryBlue, fontSize: 14))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      _buildConnectionStatus(context, state.connectionState),
                    ],
                  ),
                ),
              ],
            );
          }
          return const Text('Chat');
        },
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context, ChatSignalRState state) {
    final theme = Theme.of(context);
    String text = '';
    Color color = theme.brightness == Brightness.dark ? BrandTokens.textMuted : BrandTokens.textSecondary;
    
    switch (state) {
      case ChatSignalRState.connected:
        text = 'Online';
        color = const Color(0xFF00C896);
        break;
      case ChatSignalRState.connecting:
        text = 'Connecting...';
        color = Colors.amber;
        break;
      case ChatSignalRState.disconnected:
      case ChatSignalRState.error:
        text = 'Offline';
        color = theme.brightness == Brightness.dark ? BrandTokens.textMuted : BrandTokens.textSecondary;
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
        Text(text, style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }

  Widget _buildMessageList(HelperChatLoaded state) {
    if (state.messages.isEmpty) {
      return _buildEmptyState(state);
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Newer messages at bottom
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: state.messages.length + (state.hasReachedMax ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == state.messages.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: BrandTokens.primaryBlue),
            ),
          );
        }

        final message = state.messages[index];
        final isMe = message.senderId == state.conversation.helper.id;
        
        return MessageBubble(
          message: message,
          isMe: isMe,
        );
      },
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: BrandTokens.primaryBlue));
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: BrandTokens.dangerRed, size: 48),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? BrandTokens.textMuted : BrandTokens.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _init,
            style: ElevatedButton.styleFrom(backgroundColor: BrandTokens.primaryBlue),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(HelperChatLoaded state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, color: BrandTokens.borderSoft, size: 80),
          const SizedBox(height: 16),
          Text(
            'Start a conversation with ${state.conversation.user.name}',
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? BrandTokens.textMuted : BrandTokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return ChatInputBar(
      onSend: (text) => _cubit.sendMessage(text),
      onQuickReply: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => QuickRepliesSheet(
            onReply: (text) => _cubit.sendMessage(text),
          ),
        );
      },
    );
  }
}
