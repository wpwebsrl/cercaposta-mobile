import 'package:cercaposta/shared/models/capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Capabilities defaults fail closed', () {
    const capabilities = Capabilities();

    expect(capabilities.aiEnabled, isFalse);
    expect(capabilities.aiChat, isFalse);
    expect(capabilities.chatMemory, isFalse);
    expect(capabilities.semanticSearch, isFalse);
    expect(capabilities.aiClassification, isFalse);
    expect(capabilities.replyTracking, isFalse);
    expect(capabilities.aiUsage, isFalse);
    expect(capabilities.mcpAvailable, isFalse);
  });

  test('Capabilities parses product gates independently from MCP', () {
    final capabilities = Capabilities.fromJson(<String, dynamic>{
      'ai_enabled': true,
      'mcp_available': true,
      'capabilities': <String, dynamic>{
        'ai_chat': false,
        'chat_memory': false,
        'semantic_search': true,
        'ai_classification': false,
        'reply_tracking': true,
        'ai_usage': true,
      },
    });

    expect(capabilities.mcpAvailable, isTrue);
    expect(capabilities.aiChat, isFalse);
    expect(capabilities.semanticSearch, isTrue);
    expect(capabilities.replyTracking, isTrue);
  });
}
