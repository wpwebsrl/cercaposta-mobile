import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/models/memory.dart';
import '../../shared/widgets/snack.dart';

/// «Ho imparato: …» under a chat turn, with the two actions that make automatic learning
/// acceptable (docs/memoria-utente.md §7).
///
/// The two are NOT the same thing and must never become one button: **annulla** removes a
/// memory this turn got wrong, **non ricordare più** records a standing refusal so the same
/// signal cannot teach it again next week. Collapsing them would produce exactly the behaviour
/// that makes these systems unbearable — the proposal that keeps coming back.
class MemoryAnnouncement extends ConsumerStatefulWidget {
  const MemoryAnnouncement({super.key, required this.memory});

  final LearnedMemory memory;

  @override
  ConsumerState<MemoryAnnouncement> createState() => _MemoryAnnouncementState();
}

class _MemoryAnnouncementState extends ConsumerState<MemoryAnnouncement> {
  String? _settled; // 'undone' | 'rejected'
  bool _busy = false;

  Future<void> _act(String what) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final api = ref.read(memoryApiProvider);
      if (what == 'undone') {
        await api.delete(widget.memory.id);
      } else {
        await api.update(widget.memory.id, rejected: true);
      }
      if (mounted) setState(() => _settled = what);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showSnack(context, localizeApiError(l, e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (_settled != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.check, size: 13, color: theme.colorScheme.outline),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _settled == 'undone'
                    ? l.memoryAnnounceUndone
                    : l.memoryAnnounceRejected,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final m = widget.memory;
    final what = m.kind == 'alias'
        ? l.memoryAnnounceAlias(m.key, m.value)
        : l.memoryAnnounceGeneric(m.key, m.value);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.psychology_outlined,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  // «in prova» is a real, different state: it was noticed but is NOT being
                  // used yet.
                  m.candidate ? l.memoryAnnounceTrial(what) : what,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextButton(
                onPressed: _busy ? null : () => _act('undone'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(l.memoryAnnounceUndo),
              ),
              TextButton(
                onPressed: _busy ? null : () => _act('rejected'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(l.memoryReject),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
