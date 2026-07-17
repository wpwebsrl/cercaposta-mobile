import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/widgets/snack.dart';

const _theirTurn = 'their_turn';
const _myTurn = 'my_turn';

/// «Segna in attesa di risposta» — the mobile twin of the web `MarkFollowupDialog`
/// and the desktop `MarkFollowupDialog`, on the same `POST /followups` contract.
///
/// Returns true when an expectation was created, so the caller can tell the user.
Future<bool> showMarkFollowupSheet(
  BuildContext context, {
  required String messageId,
  required String fromAddress,
}) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _MarkFollowupSheet(messageId: messageId, fromAddress: fromAddress),
  );
  return created ?? false;
}

class _MarkFollowupSheet extends ConsumerStatefulWidget {
  const _MarkFollowupSheet({
    required this.messageId,
    required this.fromAddress,
  });

  final String messageId;
  final String fromAddress;

  @override
  ConsumerState<_MarkFollowupSheet> createState() => _MarkFollowupSheetState();
}

class _MarkFollowupSheetState extends ConsumerState<_MarkFollowupSheet> {
  /// Null until the user picks: the suggestion then fills in without ever overriding
  /// a choice already made. Same load-bearing pattern as `picked ?? suggested` on the
  /// web and the `_touched` guard on the desktop — the policy can land late, and it
  /// must not move a radio the user has already set.
  String? _picked;
  String _suggested = _myTurn;
  DateTime? _due;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _suggest();
  }

  Future<void> _suggest() async {
    final own = await ref.read(followupApiProvider).ownAddresses();
    if (!mounted || own.isEmpty) return;
    // I sent it => I am waiting on them; otherwise the ball is in my court.
    final iSentIt = own.contains(widget.fromAddress.toLowerCase());
    setState(() => _suggested = iSentIt ? _theirTurn : _myTurn);
  }

  String get _direction => _picked ?? _suggested;

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day + 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime(now.year, now.month, now.day + 3),
      firstDate: first,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(followupApiProvider)
          .create(
            widget.messageId,
            _direction,
            // End of the chosen day, like web and desktop: a deadline of "the 20th"
            // means the 20th is still in time, not that it expired at midnight.
            dueAt: _due == null
                ? null
                : DateTime(_due!.year, _due!.month, _due!.day, 23, 59, 59),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(
        context,
        localizeApiError(AppLocalizations.of(context)!, e),
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l.followupMarkTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _option(
            value: _theirTurn,
            title: l.followupMarkTheirTurn,
            hint: l.followupMarkTheirTurnHint,
          ),
          _option(
            value: _myTurn,
            title: l.followupMarkMyTurn,
            hint: l.followupMarkMyTurnHint,
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _due == null
                      ? l.followupMarkDue
                      : '${l.followupMarkDue}: ${_due!.day}/${_due!.month}/${_due!.year}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (_due != null)
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _due = null),
                  child: Text(l.actionClear),
                ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickDue,
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(l.followupMarkPickDue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.followupMarkConfirm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _option({
    required String value,
    required String title,
    required String hint,
  }) => RadioListTile<String>(
    value: value,
    groupValue: _direction,
    onChanged: _busy ? null : (v) => setState(() => _picked = v),
    contentPadding: EdgeInsets.zero,
    dense: true,
    title: Text(title),
    subtitle: Text(hint, style: Theme.of(context).textTheme.bodySmall),
  );
}
