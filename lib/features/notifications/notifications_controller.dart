import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/auth/auth_controller.dart';

/// Unread notification count for the bottom-nav badge. Reset per session; a
/// transient failure resolves to 0 (no badge). Invalidate after marking read /
/// dismissing so the badge updates. Reading it also lazily materializes any
/// pending system notification server-side (the endpoint ensures them).
final notificationUnreadCountProvider = FutureProvider<int>((ref) async {
  ref.watch(sessionKeyProvider);
  try {
    return await ref.watch(notificationApiProvider).unreadCount();
  } on Object {
    return 0;
  }
});
