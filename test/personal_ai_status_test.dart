import 'package:cercaposta/core/api/services/chat_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'personal model identity and context are preserved on native clients',
    () {
      final status = ChatStatus.fromJson({
        'ai_enabled': true,
        'llm_configured': true,
        'ai_mode': 'personal',
        'model': 'my-own-model',
        'context_window': 16384,
      });
      expect(status.available, isTrue);
      expect(status.aiMode, 'personal');
      expect(status.model, 'my-own-model');
      expect(status.contextWindow, 16384);
    },
  );

  test('legacy servers retain the managed default', () {
    expect(ChatStatus.fromJson({'ai_enabled': true}).aiMode, 'managed');
  });
}
