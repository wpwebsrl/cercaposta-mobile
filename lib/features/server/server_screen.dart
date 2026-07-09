import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/config/server_store.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers.dart';
import '../../shared/models/meta.dart';

class ServerScreen extends ConsumerStatefulWidget {
  const ServerScreen({super.key});

  @override
  ConsumerState<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends ConsumerState<ServerScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validateAndSelect(String raw) async {
    final l = AppLocalizations.of(context)!;
    final url = ServerStore.normalize(raw);
    if (url.isEmpty) return;
    if (!ServerStore.allowsCleartext(url)) {
      setState(() => _error = l.serverHttpsRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final meta = await ref.read(metaApiProvider).fetch(url);
      if (!mounted) return;
      if (!meta.looksValid) {
        setState(() => _error = l.serverNotCercaPosta);
        return;
      }
      if (meta.needsSetup) {
        setState(() => _error = l.serverNeedsSetup);
        return;
      }
      final info = ref.read(appInfoProvider);
      final minVersion = info.client == 'ios' ? meta.minIos : meta.minAndroid;
      if (versionBelow(info.version, minVersion)) {
        setState(() => _error = l.serverUpdateRequired);
        return;
      }
      await ref.read(activeServerProvider.notifier).select(url);
      // Router redirects to /login on the active-server change.
    } on Object catch (e) {
      if (mounted) setState(() => _error = localizeApiError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final saved = ref.watch(serverStoreProvider).servers();
    return Scaffold(
      appBar: AppBar(title: Text(l.serverTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l.serverSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: l.serverUrlLabel,
                hintText: l.serverUrlHint,
                errorText: _error,
                prefixIcon: const Icon(Icons.dns_outlined),
              ),
              onSubmitted: _busy ? null : _validateAndSelect,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _validateAndSelect(_controller.text),
              child: _busy ? Text(l.serverValidating) : Text(l.actionContinue),
            ),
            if (saved.isNotEmpty) ...<Widget>[
              const SizedBox(height: 24),
              Text(
                l.serverSavedTitle,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              ...saved.map(
                (s) => ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(s),
                  onTap: _busy ? null : () => _validateAndSelect(s),
                  trailing: IconButton(
                    tooltip: l.serverRemoveSaved,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _busy
                        ? null
                        : () async {
                            await ref.read(serverStoreProvider).remove(s);
                            if (mounted) setState(() {});
                          },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
