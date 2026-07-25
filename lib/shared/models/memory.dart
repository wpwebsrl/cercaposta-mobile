import '../../core/api/json.dart';

/// Chat memory: what the assistant remembers about this user (docs/memoria-utente.md).
///
/// The EFFECT of a memory is entirely server-side — the app gets it for free in every answer,
/// without knowing a thing. What lives here is only what the client must *manage*: the list,
/// the two policy switches and the inline announcement.
///
/// `kind` says WHERE a memory acts and `trigger` says WHEN; both are machine enums decided by
/// the server, so this file mirrors them (the labels live in the ARB catalogues, never here).
const List<String> memoryKinds = <String>[
  'alias',
  'param',
  'render',
  'fact',
  'shortcut',
];

/// Derived server-side, never a column: rejected → disabled → trial → active.
const List<String> memoryStatuses = <String>[
  'active',
  'trial',
  'rejected',
  'disabled',
];

class Memory {
  const Memory({
    required this.id,
    required this.kind,
    required this.trigger,
    required this.key,
    required this.value,
    required this.source,
    required this.confidence,
    required this.status,
    required this.stale,
    required this.uses,
    required this.lastUsedAt,
  });

  final String id;
  final String kind;
  final String trigger;
  final String key;
  final String value;
  final String source;
  final double confidence;
  final String status;

  /// Applied by nothing for months: the screen PROPOSES pausing it, and does nothing itself.
  final bool stale;
  final int uses;
  final DateTime? lastUsedAt;

  factory Memory.fromJson(Map<String, dynamic> j) => Memory(
    id: jsonStr(j, 'id'),
    kind: jsonStr(j, 'kind', 'fact'),
    trigger: jsonStr(j, 'trigger', 'always'),
    key: jsonStr(j, 'key'),
    value: jsonStr(j, 'value'),
    source: jsonStr(j, 'source', 'explicit'),
    confidence: jsonDouble(j, 'confidence'),
    status: jsonStr(j, 'status', 'active'),
    stale: jsonBool(j, 'stale'),
    uses: jsonInt(j, 'uses'),
    lastUsedAt: jsonDate(j, 'last_used_at'),
  );
}

/// The two switches. `enabled` pauses the memories without losing them, `learn` stops the
/// automatic channels — the difference between «pausa» and «dimentica tutto».
class MemoryPolicy {
  const MemoryPolicy({
    this.enabled = true,
    this.learn = true,
    this.maxItems = 200,
  });

  final bool enabled;
  final bool learn;
  final int maxItems;

  factory MemoryPolicy.fromJson(Map<String, dynamic> j) => MemoryPolicy(
    enabled: jsonBool(j, 'enabled', true),
    learn: jsonBool(j, 'learn', true),
    maxItems: jsonInt(j, 'max_items', 200),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'enabled': enabled,
    'learn': learn,
    'max_items': maxItems,
  };

  MemoryPolicy copyWith({bool? enabled, bool? learn}) => MemoryPolicy(
    enabled: enabled ?? this.enabled,
    learn: learn ?? this.learn,
    maxItems: maxItems,
  );
}

/// An alias the archive suggests — computed on demand, stored only if the user accepts.
class AliasSuggestion {
  const AliasSuggestion({
    required this.key,
    required this.value,
    required this.name,
    required this.count,
  });

  final String key;
  final String value;
  final String name;
  final int count;

  factory AliasSuggestion.fromJson(Map<String, dynamic> j) => AliasSuggestion(
    key: jsonStr(j, 'key'),
    value: jsonStr(j, 'value'),
    name: jsonStr(j, 'name'),
    count: jsonInt(j, 'count'),
  );
}

/// The `data-memory` part of the chat stream: one memory learned during this turn.
///
/// `status` is "learned" (in force now) or "candidate" (on trial, changing nothing yet) — two
/// different sentences, because one of them altered the answer and the other did not.
class LearnedMemory {
  const LearnedMemory({
    required this.id,
    required this.kind,
    required this.key,
    required this.value,
    required this.status,
  });

  final String id;
  final String kind;
  final String key;
  final String value;
  final String status;

  bool get candidate => status == 'candidate';

  factory LearnedMemory.fromJson(Map<String, dynamic> j) => LearnedMemory(
    id: jsonStr(j, 'id'),
    kind: jsonStr(j, 'kind'),
    key: jsonStr(j, 'key'),
    value: jsonStr(j, 'value'),
    status: jsonStr(j, 'status', 'learned'),
  );
}

/// One memory the server applied to THIS answer (`message-metadata.applied_memories`).
class AppliedMemory {
  const AppliedMemory({required this.key, required this.value});

  final String key;
  final String value;

  String get label => value.isEmpty ? key : '$key → $value';

  factory AppliedMemory.fromJson(Map<String, dynamic> j) =>
      AppliedMemory(key: jsonStr(j, 'key'), value: jsonStr(j, 'value'));
}
