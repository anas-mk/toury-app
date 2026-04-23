import '../models/chat_model.dart';
import '../models/message_model.dart';

abstract class ChatService {
  Future<ChatModel> getChatInfo(String bookingId);
  Future<List<MessageModel>> getMessages(String bookingId, {int page = 1, int pageSize = 20, DateTime? before});
  Future<MessageModel> sendMessage(String bookingId, String text, String messageType);
  Future<void> markAsRead(String bookingId);
}
