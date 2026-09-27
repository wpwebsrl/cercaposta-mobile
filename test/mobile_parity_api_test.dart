import 'dart:convert';
import 'package:cercaposta/core/api/services/ai_report_api.dart';
import 'package:cercaposta/core/api/services/client_updates_api.dart';
import 'package:cercaposta/core/api/services/taxonomy_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final path = options.path;
    Object body;
    var status = 200;
    if (path == '/ai-content-reports') {
      body = <String, dynamic>{'id': 'r1', 'created': true, 'status': 'open'};
    } else if (path == '/client-updates/store/products') {
      body = <String, dynamic>{
        'products': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'ios',
            'url': 'https://apps.apple.com/app/id123',
          },
        ],
      };
    } else if (path == '/tags' && options.method == 'POST') {
      status = 201;
      body = <String, dynamic>{'id': 't1', 'name': 'Fatture', 'color': 'blue'};
    } else if (path == '/tags/t1' && options.method == 'PATCH') {
      body = <String, dynamic>{
        'id': 't1',
        'name': 'Contabilità',
        'color': 'teal',
      };
    } else if (path.contains('/messages/')) {
      body = <Map<String, dynamic>>[
        <String, dynamic>{'id': 't1', 'name': 'Contabilità', 'color': 'teal'},
      ];
    } else {
      body = <dynamic>[];
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_RecordingAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;

void main() {
  test('AI report sends only the persisted ID and review metadata', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final adapter = _RecordingAdapter();

    expect(
      await AiReportApi(_dio(adapter)).create(
        messageId: 'a1',
        reason: 'misleading',
        comment: '  Numbers do not match.  ',
      ),
      isTrue,
    );

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/ai-content-reports');
    expect(request.data, <String, dynamic>{
      'message_id': 'a1',
      'reason': 'misleading',
      'comment': 'Numbers do not match.',
      'source_client': 'ios',
    });
    expect((request.data as Map).containsKey('response'), isFalse);
  });

  test('tag CRUD and message assignment match server routes', () async {
    final adapter = _RecordingAdapter();
    final api = TaxonomyApi(_dio(adapter));

    final created = await api.createTag('Fatture', 'blue');
    final updated = await api.updateTag(
      created.id,
      name: 'Contabilità',
      color: 'teal',
    );
    final assigned = await api.addMessageTag('m1', created.id);
    final removed = await api.removeMessageTag('m1', created.id);
    await api.deleteTag(created.id);

    expect(updated.name, 'Contabilità');
    expect(assigned.single.color, 'teal');
    expect(removed.single.id, 't1');
    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      <String>[
        'POST /tags',
        'PATCH /tags/t1',
        'POST /messages/m1/tags/t1',
        'DELETE /messages/m1/tags/t1',
        'DELETE /tags/t1',
      ],
    );
  });

  test('store catalog accepts only the requested HTTPS listing', () async {
    final adapter = _RecordingAdapter();
    final api = ClientUpdatesApi(_dio(adapter));

    expect(
      await api.storeUrl('ios'),
      Uri.parse('https://apps.apple.com/app/id123'),
    );
    expect(await api.storeUrl('android'), isNull);
  });
}
