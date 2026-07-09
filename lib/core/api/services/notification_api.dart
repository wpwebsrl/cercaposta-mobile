import 'package:dio/dio.dart';

import '../../../shared/models/notification.dart';
import '../json.dart';

class NotificationApi {
  NotificationApi(this._dio);
  final Dio _dio;

  Future<NotificationList> list() async {
    final resp = await _dio.get<dynamic>('/notifications');
    return NotificationList.fromJson(mapOf(resp.data));
  }

  Future<int> unreadCount() async {
    final resp = await _dio.get<dynamic>('/notifications/unread-count');
    return jsonInt(mapOf(resp.data), 'unread_count');
  }

  Future<void> markAllRead() => _dio.post<dynamic>('/notifications/read-all');

  Future<void> dismiss(String id) =>
      _dio.post<dynamic>('/notifications/$id/dismiss');
}
