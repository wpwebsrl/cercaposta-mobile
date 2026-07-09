import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/providers.dart';
import '../../shared/models/meta.dart';

/// Whether the active server's FEATURE floor is above this build (docs/aggiornamenti.md).
/// Below it the app must update: since mobile can't auto-update, HomeShell turns this into
/// a hard block that routes to the store. Re-checked on resume, not just at server selection.
/// A transient /meta failure resolves to false — don't block when merely offline.
final updateRequiredProvider = FutureProvider<bool>((ref) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return false;
  try {
    final meta = await ref.watch(metaApiProvider).fetch(server);
    final info = ref.watch(appInfoProvider);
    return versionBelow(info.version, meta.featureMinFor(info.client));
  } on Object {
    return false;
  }
});
