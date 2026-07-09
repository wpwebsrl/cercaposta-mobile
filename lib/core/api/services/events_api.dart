import 'package:dio/dio.dart';

import '../json.dart';

/// One snapshot of the live-change state (docs/eventi-live.md): the three per-user revision
/// counters plus the notification unread count. The mobile app polls this (foreground + on
/// resume) — no persistent SSE stream, to spare the radio and battery — and re-fetches whatever
/// scope advanced.
class EventsState {
  const EventsState({required this.revs, required this.unreadCount});

  final Map<String, int> revs;
  final int unreadCount;

  factory EventsState.fromJson(Map<String, dynamic> j) {
    final r = jsonMap(j, 'revs');
    return EventsState(
      revs: <String, int>{
        'archive': jsonInt(r, 'archive'),
        'shares': jsonInt(r, 'shares'),
        'notifications': jsonInt(r, 'notifications'),
      },
      unreadCount: jsonInt(j, 'unread_count'),
    );
  }
}

class EventsApi {
  EventsApi(this._dio);
  final Dio _dio;

  Future<EventsState> state() async {
    final resp = await _dio.get<dynamic>('/events/state');
    return EventsState.fromJson(mapOf(resp.data));
  }
}
