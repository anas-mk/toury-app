import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/helper_chat_cubit.dart';
import '../cubit/helper_chat_state.dart';
import '../widgets/helper_message_bubble.dart';

class HelperChatScreen extends StatefulWidget {
  final String bookingId;

  const HelperChatScreen({super.key, required this.bookingId});

  @override
  State<HelperChatScreen> createState() => _HelperChatScreenState();
}

class _HelperChatScreenState extends State<HelperChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<HelperChatCubit>().initChat(widget.bookingId);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<HelperChatCubit>().loadMoreMessages();
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      context.read<HelperChatCubit>().sendMessage(text, 'Text');
      _messageController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<HelperChatCubit, HelperChatState>(
          builder: (context, state) {
            if (state is HelperChatLoaded) {
              return Row(
                children: [
                  CircleAvatar(
                    backgroundImage: state.chatInfo.touristImage != null
                        ? NetworkImage(state.chatInfo.touristImage!)
                        : null,
                    child: state.chatInfo.touristImage == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.chatInfo.touristName, style: const TextStyle(fontSize: 16)),
                        const Text(
                          'Customer',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const Text('Chat');
          },
        ),
      ),
      body: BlocConsumer<HelperChatCubit, HelperChatState>(
        listener: (context, state) {
          if (state is HelperChatError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is HelperChatLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HelperChatLoaded) {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final message = state.messages[index];
                      return HelperMessageBubble(
                        message: message,
                        isMe: message.senderRole == 'Helper',
                      );
                    },
                  ),
                ),
                _buildInputBar(),
              ],
            );
          }

          if (state is HelperChatError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: () => context.read<HelperChatCubit>().initChat(widget.bookingId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black12, offset: const Offset(0, -1), blurRadius: 4),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ),
            IconButton(
              onPressed: _sendMessage,
              icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
