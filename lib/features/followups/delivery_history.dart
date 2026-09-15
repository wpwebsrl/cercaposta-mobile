import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/i18n/app_localizations.dart';

class DeliveryHistory extends ConsumerStatefulWidget {
  const DeliveryHistory({super.key, required this.expectationId});
  final String expectationId;
  @override
  ConsumerState<DeliveryHistory> createState() => _DeliveryHistoryState();
}

class _DeliveryHistoryState extends ConsumerState<DeliveryHistory> {
  late Future<List<Map<String, dynamic>>> _rows;
  final _checked = <String>{};
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _rows = _load();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      ref.read(followupApiProvider).deliveries(widget.expectationId);

  Future<void> _resolve(String id, bool accepted) async {
    if (_busy || !_checked.contains(id)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(followupApiProvider)
          .resolveDelivery(id, accepted: accepted);
      if (!mounted) return;
      setState(() {
        _rows = _load();
        _checked.remove(id);
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _state(AppLocalizations l, String state) => switch (state) {
    'sent' => l.deliverySent,
    'sending' => l.deliverySending,
    'failed' => l.deliveryFailed,
    _ => l.deliveryUnknown,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(l.deliveryHistory, style: const TextStyle(fontSize: 13)),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: l.deliveryHistory,
            icon: const Icon(Icons.refresh),
            onPressed: _busy ? null : () => setState(() => _rows = _load()),
          ),
        ),
        if (_error != null) Text(localizeApiError(l, _error!)),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _rows,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(localizeApiError(l, snapshot.error!));
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            if (snapshot.data!.isEmpty) return Text(l.deliveryEmpty);
            return Column(
              children: snapshot.data!.map((row) {
                final id = row['id'] as String;
                final date = DateTime.tryParse(
                  row['created_at'] as String? ?? '',
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${date == null ? '' : DateFormat.yMd(l.localeName).add_Hm().format(date.toLocal())} · ${row['provider']} · ${_state(l, row['state'] as String)}',
                      ),
                      SelectableText(
                        '${l.deliveryReference}: $id',
                        style: const TextStyle(fontSize: 11),
                      ),
                      if (row['can_resolve'] == true) ...[
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l.deliveryChecked,
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: _checked.contains(id),
                          onChanged: _busy
                              ? null
                              : (value) => setState(() {
                                  value == true
                                      ? _checked.add(id)
                                      : _checked.remove(id);
                                }),
                        ),
                        Wrap(
                          children: [
                            for (final accepted in [true, false])
                              TextButton(
                                onPressed: _busy || !_checked.contains(id)
                                    ? null
                                    : () => _resolve(id, accepted),
                                child: Text(
                                  accepted
                                      ? l.deliveryConfirmSent
                                      : l.deliveryConfirmFailed,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
