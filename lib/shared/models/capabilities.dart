import '../../core/api/json.dart';

/// Server-authoritative commercial gates for the current account.
///
/// The default is intentionally deny-all so paid AI surfaces never flash while
/// login or a plan refresh is still in flight. MCP remains an independent gate.
class Capabilities {
  const Capabilities({
    this.aiEnabled = false,
    this.aiChat = false,
    this.chatMemory = false,
    this.semanticSearch = false,
    this.aiClassification = false,
    this.replyTracking = false,
    this.aiUsage = false,
    this.mcpAvailable = false,
  });

  final bool aiEnabled;
  final bool aiChat;
  final bool chatMemory;
  final bool semanticSearch;
  final bool aiClassification;
  final bool replyTracking;
  final bool aiUsage;
  final bool mcpAvailable;

  factory Capabilities.fromJson(Map<String, dynamic> j) {
    final caps = jsonMap(j, 'capabilities');
    return Capabilities(
      aiEnabled: jsonBool(j, 'ai_enabled'),
      aiChat: jsonBool(caps, 'ai_chat'),
      chatMemory: jsonBool(caps, 'chat_memory'),
      semanticSearch: jsonBool(caps, 'semantic_search'),
      aiClassification: jsonBool(caps, 'ai_classification'),
      replyTracking: jsonBool(caps, 'reply_tracking'),
      aiUsage: jsonBool(caps, 'ai_usage'),
      mcpAvailable: jsonBool(j, 'mcp_available'),
    );
  }
}
