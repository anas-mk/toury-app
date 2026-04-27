import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/services/signalr/booking_hub_events.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../models/chat_models.dart';

abstract class UserChatRemoteDataSource {
  Future<ChatConversationModel> getConversation(String bookingId);
  Future<List<ChatMessageModel>> getMessages(String bookingId, {int page = 1, DateTime? beforeDate});
  Future<ChatMessageModel> sendMessage({required String bookingId, required String text, required String type});
  Future<void> markAsRead(String bookingId);
  Stream<ChatMessageModel> listenIncomingMessages();
}

class UserChatRemoteDataSourceImpl implements UserChatRemoteDataSource {
  final Dio dio;
  final BookingTrackingHubService hubService;

  final _messageStreamController = StreamController<ChatMessageModel>.broadcast();
  StreamSubscription<ChatMessagePushEvent>? _hubSub;

  UserChatRemoteDataSourceImpl({
    required this.dio,
    required this.hubService,
  }) {
    _hubSub = hubService.chatMessageStream.listen(_onChatPush);
    unawaited(_ensureHubConnected());
  }

  Future<void> _ensureHubConnected() async {
    try {
      await hubService.ensureConnected();
    } catch (e) {
      debugPrint('💬 UserChatRemoteDataSource: hub ensureConnected failed → $e');
    }
  }

  void _onChatPush(ChatMessagePushEvent event) {
    final id = event.messageId;
    if (id == null || id.isEmpty) return;
    final senderId = event.senderId ?? '';
    final senderType = event.senderType ?? 'User';
    final messageType = event.messageType ?? 'Text';
    final preview = event.preview ?? '';
    final sentAt = event.sentAt ?? DateTime.now().toUtc();
    _messageStreamController.add(
      ChatMessageModel(
        id: id,
        senderId: senderId,
        senderType: senderType,
        messageType: messageType,
        text: preview,
        sentAt: sentAt,
        isRead: false,
      ),
    );
  }

  void dispose() {
    _hubSub?.cancel();
    _messageStreamController.close();
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      if (data == null) return raw;
    }
    return raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  }

  List<dynamic> _unwrapList(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic> && data['items'] is List) {
        return data['items'] as List;
      }
      if (raw['items'] is List) return raw['items'] as List;
    }
    if (raw is List) return raw;
    return const [];
  }

  Never _throwFromDio(DioException e, String label) {
    if (e.error is UnauthorizedException) throw e.error as UnauthorizedException;
    if (e.error is ForbiddenException) throw e.error as ForbiddenException;
    final code = e.response?.statusCode;
    final body = e.response?.data;
    String? msg;
    if (body is Map && body['message'] is String) {
      msg = body['message'] as String;
    }
    debugPrint('💬 [$label] HTTP $code → ${msg ?? e.message}');
    if (code == 401) throw UnauthorizedException(msg ?? 'Unauthorized');
    if (code == 403) throw ForbiddenException(msg ?? 'Forbidden');
    throw ServerException(msg ?? e.message ?? 'Network error');
  }

  @override
  Future<ChatConversationModel> getConversation(String bookingId) async {
    try {
      final response = await dio.get(ApiConfig.getChatConversation(bookingId));
      return ChatConversationModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      _throwFromDio(e, 'getConversation');
    }
  }

  @override
  Future<List<ChatMessageModel>> getMessages(String bookingId, {int page = 1, DateTime? beforeDate}) async {
    try {
      final response = await dio.get(
        ApiConfig.getChatMessages(bookingId, page: page, beforeDate: beforeDate?.toIso8601String()),
      );
      final items = _unwrapList(response.data);
      return items
          .whereType<Map<String, dynamic>>()
          .map(ChatMessageModel.fromJson)
          .toList();
    } on DioException catch (e) {
      _throwFromDio(e, 'getMessages');
    }
  }

  @override
  Future<ChatMessageModel> sendMessage({required String bookingId, required String text, required String type}) async {
    try {
      final response = await dio.post(
        ApiConfig.sendChatMessage(bookingId),
        data: {
          'text': text,
          'messageType': type,
        },
      );
      return ChatMessageModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      _throwFromDio(e, 'sendMessage');
    }
  }

  @override
  Future<void> markAsRead(String bookingId) async {
    try {
      await dio.post(ApiConfig.markChatAsRead(bookingId));
    } on DioException catch (e) {
      _throwFromDio(e, 'markAsRead');
    }
  }

  @override
  Stream<ChatMessageModel> listenIncomingMessages() {
    return _messageStreamController.stream;
  }
}
