import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../core/theme/app_color.dart';
import '../cubit/user_chat_cubit.dart';
import '../cubit/user_chat_state.dart';
import '../widgets/chat_bubble_widget.dart';
import '../widgets/chat_input_widget.dart';

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<UserChatCubit>().loadMoreMessages(widget.bookingId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<UserChatCubit>()..initChat(widget.bookingId),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<UserChatCubit, UserChatState>(
                builder: (context, state) {
                  if (state is UserChatLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (state is UserChatError) {
                    return Center(child: Text(state.message));
                  }
                  
                  if (state is UserChatLoaded) {
                    if (state.messages.isEmpty) {
                      return _buildEmptyState();
                    }
                    
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: state.messages.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.messages.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        
                        final message = state.messages[index];
                        final isMe = message.senderId == state.conversation.user.id;
                        
                        return ChatBubbleWidget(
                          message: message,
                          isMe: isMe,
                        );
                      },
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),
            BlocBuilder<UserChatCubit, UserChatState>(
              builder: (context, state) {
                return ChatInputWidget(
                  onSend: (text) => context.read<UserChatCubit>().sendMessage(widget.bookingId, text),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          Hero(
            tag: 'chat_avatar_${widget.bookingId}',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AppNetworkImage(
                  imageUrl: widget.helperImage ?? '',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.helperName ?? 'Helper',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColor.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColor.primaryColor),
          ),
          const SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start your conversation with your helper',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
