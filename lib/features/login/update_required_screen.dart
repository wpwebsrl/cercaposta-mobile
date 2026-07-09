import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/providers.dart';

/// Full-screen, non-dismissible block shown when the server rejects this app
/// version (426). The only way forward is to update from the store.
class UpdateRequiredScreen extends ConsumerStatefulWidget {
  const UpdateRequiredScreen({super.key});

  @override
  ConsumerState<UpdateRequiredScreen> createState() =>
      _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends ConsumerState<UpdateRequiredScreen> {
  bool _busy = false;

  Future<void> _openStore() async {
    final l = AppLocalizations.of(context)!;
    final uris = ref.read(appInfoProvider).storeUpdateUris();
    setState(() => _busy = true);
    var opened = false;
    for (final uri in uris) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (opened) break;
      } on Object {
        // try the next candidate (store app missing → web fallback)
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.updateStoreError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final current = ref.read(appInfoProvider).version;
    // Block the system back gesture/button: the app is unusable until updated.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(
                    Icons.system_update,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l.updateRequiredTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.updateRequiredBody(current),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _busy ? null : _openStore,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l.updateRequiredButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
