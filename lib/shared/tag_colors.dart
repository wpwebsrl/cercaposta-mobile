import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_providers.dart';
import '../core/auth/auth_controller.dart';

/// Tag dot colors, matching the web (theme.css) and desktop (TAG_HEX) palette.
const Map<String, Color> _tagHex = <String, Color>{
  'gray': Color(0xFF6B7680),
  'red': Color(0xFFE5534B),
  'orange': Color(0xFFE8833A),
  'yellow': Color(0xFFD4A72C),
  'green': Color(0xFF4AC26B),
  'teal': Color(0xFF33B3A6),
  'blue': Color(0xFF4596E6),
  'purple': Color(0xFF986EE2),
  'pink': Color(0xFFE275AD),
};

/// Resolve a tag color name (gray|red|…) to its dot color, gray as fallback.
Color tagColor(String name) => _tagHex[name] ?? _tagHex['gray']!;

/// Lowercased tag name → (original-case name, color name), fetched once per
/// session. Search hits carry tag names **lowercased** by the index, so the
/// results list keys by lowercase to recover BOTH the real color and the
/// original casing (e.g. "Fatture", not "fatture"). Watching the session key
/// drops the map on logout/user switch. Failures degrade to empty.
typedef TagInfo = ({String name, String color});

final tagColorsProvider = FutureProvider<Map<String, TagInfo>>((ref) async {
  ref.watch(sessionKeyProvider);
  try {
    final tags = await ref.watch(taxonomyApiProvider).tags();
    return <String, TagInfo>{
      for (final t in tags)
        t.name.toLowerCase(): (name: t.name, color: t.color),
    };
  } on Object {
    return const <String, TagInfo>{};
  }
});
