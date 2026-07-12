import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/auth/auth_controller.dart';

/// Notification badge count + the follow-up overdue count, in one fetch. Reset per
/// session; a transient failure resolves to zeros (no badge). Invalidate after
/// marking read / dismissing, or when the live-refresh notifications rev advances,
/// so both badges update. Reading it also lazily materializes any pending system
/// notification and follow-up deadline server-side (the endpoint ensures them).
final notificationUnreadCountProvider =
    FutureProvider<({int unread, int followupOverdue})>((ref) async {
      ref.watch(sessionKeyProvider);
      try {
        return await ref.watch(notificationApiProvider).counts();
      } on Object {
        return (unread: 0, followupOverdue: 0);
      }
    });
