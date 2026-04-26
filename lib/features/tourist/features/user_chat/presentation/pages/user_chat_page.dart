import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/user_chat_cubit.dart';
import '../cubit/user_chat_state.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/di/injection_container.dart';
import '../widgets/chat_message_bubble.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => sl<UserChatCubit>()..loadMessages(widget.bookingId),
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chat with Helper'),
              Text('Online', style: TextStyle(fontSize: 10, color: AppColor.accentColor)),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<UserChatCubit, UserChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ChatLoaded) {
                    if (state.messages.isEmpty) {
                      return const Center(child: Text('Start a conversation...'));
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(AppTheme.spaceLG),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        return ChatMessageBubble(
                          message: state.messages[index],
                          isMe: state.messages[index].senderType == 'User',
                        );
                      },
                    );
                  }
                  if (state is ChatError) {
                    return Center(child: Text(state.message));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            _buildInputArea(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spaceLG,
        AppTheme.spaceMD,
        AppTheme.spaceLG,
        MediaQuery.of(context).padding.bottom + AppTheme.spaceMD,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: AppColor.lightSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          BlocBuilder<UserChatCubit, UserChatState>(
            builder: (context, state) {
              final isSending = state is ChatLoaded && state.isSending;
              return CircleAvatar(
                backgroundColor: AppColor.primaryColor,
                child: IconButton(
                  icon: isSending 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: isSending ? null : () {
                    if (_messageController.text.trim().isNotEmpty) {
                      context.read<UserChatCubit>().sendMessage(
                        widget.bookingId,
                        _messageController.text.trim(),
                      );
                      _messageController.clear();
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
