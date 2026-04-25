import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../models/helper_chat_models.dart';

abstract class HelperChatRemoteDataSource {
  Future<ConversationModel> getConversation(String bookingId, {CancelToken? cancelToken});
  Future<List<ChatMessageModel>> getMessages(
    String bookingId, {
    DateTime? before,
    int pageSize = 50,
    CancelToken? cancelToken,
  });
  Future<ChatMessageModel> sendMessage(String bookingId, String text, {CancelToken? cancelToken});
  Future<void> markAsRead(String bookingId, {CancelToken? cancelToken});
}

class HelperChatRemoteDataSourceImpl implements HelperChatRemoteDataSource {
  final Dio dio;
  HelperChatRemoteDataSourceImpl(this.dio);

  String _msg(DioException e) {
    if (CancelToken.isCancel(e)) return 'Request cancelled';
    final data = e.response?.data;
    if (data is Map) return (data['message'] ?? data['error'] ?? 'Request failed').toString();
    return e.message ?? 'Connection error. Please try again.';
  }

  void _assertOk(Response response) {
    final s = response.statusCode ?? 0;
    if (s == 400) {
      final d = response.data;
      throw ValidationException(d is Map ? (d['message'] ?? d['error'] ?? 'Validation error').toString() : 'Validation error');
    }
    if (s == 401) throw UnauthorizedException();
    if (s == 403) throw ForbiddenException();
    if (s == 404) throw NotFoundException();
    if (s >= 400) {
      final d = response.data;
      throw ServerException(d is Map ? (d['message'] ?? 'Request failed').toString() : 'Request failed');
    }
  }

  Map<String, dynamic> _data(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) return raw['data'] as Map<String, dynamic>;
      return raw;
    }
    return {};
  }

  @override
  Future<ConversationModel> getConversation(String bookingId, {CancelToken? cancelToken}) async {
    try {
      final res = await dio.get(ApiConfig.helperConversation(bookingId), cancelToken: cancelToken);
      _assertOk(res);
      return ConversationModel.fromJson(_data(res.data));
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<List<ChatMessageModel>> getMessages(
    String bookingId, {
    DateTime? before,
    int pageSize = 50,
    CancelToken? cancelToken,
  }) async {
    try {
      final params = <String, dynamic>{'pageSize': pageSize};
      if (before != null) params['beforeDateTime'] = before.toIso8601String();

      final res = await dio.get(
        ApiConfig.helperChatMessages(bookingId),
        queryParameters: params,
        cancelToken: cancelToken,
      );
      _assertOk(res);
      final raw = res.data;
      final list = (raw is Map && raw['data'] is List)
          ? raw['data'] as List
          : (raw is List ? raw : []);
      return list.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<ChatMessageModel> sendMessage(String bookingId, String text, {CancelToken? cancelToken}) async {
    try {
      final res = await dio.post(
        ApiConfig.helperSendChatMessage(bookingId),
        data: {'text': text, 'messageType': 'text'},
        cancelToken: cancelToken,
      );
      _assertOk(res);
      return ChatMessageModel.fromJson(_data(res.data));
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<void> markAsRead(String bookingId, {CancelToken? cancelToken}) async {
    try {
      final res = await dio.post(ApiConfig.helperMarkChatRead(bookingId), cancelToken: cancelToken);
      _assertOk(res);
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }
}
