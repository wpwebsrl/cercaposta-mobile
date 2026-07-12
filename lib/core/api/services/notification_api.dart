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

  /// Unread badge + the follow-up overdue count in ONE call: the endpoint returns
  /// both, and `followup_overdue` is a cleartext count (robust to a locked vault)
  /// that drives the amber badge on the «In attesa» nav entry.
  Future<({int unread, int followupOverdue})> counts() async {
    final resp = await _dio.get<dynamic>('/notifications/unread-count');
    final j = mapOf(resp.data);
    return (
      unread: jsonInt(j, 'unread_count'),
      followupOverdue: jsonInt(j, 'followup_overdue'),
    );
  }

  Future<void> markAllRead() => _dio.post<dynamic>('/notifications/read-all');

  Future<void> dismiss(String id) =>
      _dio.post<dynamic>('/notifications/$id/dismiss');

  /// Dismiss every notification at once (also marks unread ones read, so the badge
  /// drops). Still-due system/follow-up notifications aren't re-materialized.
  Future<void> dismissAll() => _dio.post<dynamic>('/notifications/dismiss-all');
}
