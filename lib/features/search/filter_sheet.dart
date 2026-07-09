import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/models/taxonomy.dart';

/// Opens the filter form and returns a composed omnibox query string (operators),
/// or null if cancelled. Mirrors the web FilterBuilder: it writes operators that
/// the server-side parser (/search/parse) interprets. The CURRENT query is parsed
/// to prefill the form, and parts the form doesn't edit (free text, folders,
/// account, size) are preserved and re-emitted on Apply.
Future<String?> showFilterSheet(BuildContext context, String currentQuery) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _FilterSheet(initial: currentQuery),
  );
}

String _token(String op, String value) {
  final v = value.trim();
  if (v.isEmpty) return '';
  return v.contains(' ') ? '$op:"$v"' : '$op:$v';
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial});
  final String initial;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _subject = TextEditingController();
  final _ext = TextEditingController();
  final _account = TextEditingController();
  final _sizeValue = TextEditingController();
  String _sizeOp = '>'; // '>' or '<'
  String _sizeUnit = 'MB';
  bool _hasAttachments = false;
  DateTime? _after;
  DateTime? _before;
  final Set<String> _tags = <String>{};
  List<TagInfo> _allTags = const <TagInfo>[];
  // Parts of the current query the form doesn't edit, preserved on Apply.
  String _freeText = '';
  List<String> _folders = const <String>[];

  static const Map<String, int> _sizeUnits = <String, int>{
    'B': 1,
    'KB': 1024,
    'MB': 1024 * 1024,
    'GB': 1024 * 1024 * 1024,
  };

  @override
  void initState() {
    super.initState();
    _loadTags();
    _prefill();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await ref.read(taxonomyApiProvider).tags();
      if (mounted) setState(() => _allTags = tags);
    } on Object {
      // tags optional
    }
  }

  /// Parse the current omnibox string server-side and prefill the form, so
  /// applying filters REFINES the query instead of replacing it.
  Future<void> _prefill() async {
    if (widget.initial.trim().isEmpty) return;
    try {
      final parsed = await ref.read(searchApiProvider).parse(widget.initial);
      if (!mounted) return;
      final f = parsed.filters;
      setState(() {
        _freeText = parsed.text;
        _from.text = f['from'] is String ? f['from'] as String : '';
        _to.text = f['to'] is String ? f['to'] as String : '';
        _subject.text = f['subject'] is String ? f['subject'] as String : '';
        _ext.text = f['attachment_ext'] is String
            ? f['attachment_ext'] as String
            : '';
        _hasAttachments = f['has_attachments'] == true;
        _after = f['date_from'] is String
            ? DateTime.tryParse(f['date_from'] as String)
            : null;
        _before = f['date_to'] is String
            ? DateTime.tryParse(f['date_to'] as String)
            : null;
        final tags = f['tag'];
        if (tags is List) _tags.addAll(tags.whereType<String>());
        final folders = f['folder'];
        _folders = folders is List
            ? folders.whereType<String>().toList()
            : const <String>[];
        _account.text = f['account_id'] is String
            ? f['account_id'] as String
            : '';
        final sizeGt = f['size_gt'] is num
            ? (f['size_gt'] as num).toInt()
            : null;
        final sizeLt = f['size_lt'] is num
            ? (f['size_lt'] as num).toInt()
            : null;
        _prefillSize(sizeGt, sizeLt);
      });
    } on Object {
      // Best effort: an unreadable query just starts the form blank.
    }
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _subject.dispose();
    _ext.dispose();
    _account.dispose();
    _sizeValue.dispose();
    super.dispose();
  }

  /// Show a preserved `dim:` filter (stored in bytes) in the largest unit that
  /// divides it evenly, so editing round-trips cleanly.
  void _prefillSize(int? sizeGt, int? sizeLt) {
    final bytes = sizeGt ?? sizeLt;
    if (bytes == null || bytes <= 0) return;
    _sizeOp = sizeGt != null ? '>' : '<';
    for (final unit in <String>['GB', 'MB', 'KB', 'B']) {
      final m = _sizeUnits[unit]!;
      if (bytes % m == 0) {
        _sizeUnit = unit;
        _sizeValue.text = (bytes ~/ m).toString();
        return;
      }
    }
  }

  /// Byte value of the size row, or null when empty/invalid (dropped silently).
  int? _sizeBytes() {
    final raw = _sizeValue.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final n = double.tryParse(raw);
    if (n == null || n <= 0) return null;
    return (n * _sizeUnits[_sizeUnit]!).round();
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _apply() {
    final parts = <String>[
      _token('da', _from.text),
      _token('a', _to.text),
      _token('oggetto', _subject.text),
      if (_ext.text.trim().isNotEmpty)
        _token('ha', _ext.text)
      else if (_hasAttachments)
        'ha:allegato',
      if (_after != null) 'dopo:${_iso(_after!)}',
      if (_before != null) 'prima:${_iso(_before!)}',
      ..._tags.map((t) => _token('tag', t)),
      if (_account.text.trim().isNotEmpty) _token('account', _account.text),
      if (_sizeBytes() != null) 'dim:$_sizeOp${_sizeBytes()}',
      // Preserved, non-edited parts of the original query:
      ..._folders.map((f) => _token('cartella', f)),
      _freeText,
    ].where((s) => s.isNotEmpty);
    Navigator.pop(context, parts.join(' ').trim());
  }

  Future<void> _pickDate({required bool after}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (after ? _after : _before) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => after ? _after = picked : _before = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l.filtersTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _field(_from, l.filterFrom, Icons.person_outline),
            _field(_to, l.filterTo, Icons.group_outlined),
            _field(_subject, l.filterSubject, Icons.subject),
            _field(_ext, l.filterAttachmentExt, Icons.attach_file),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.filterHasAttachments),
              value: _hasAttachments,
              onChanged: (v) => setState(() => _hasAttachments = v),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(after: true),
                    child: Text(
                      _after == null ? l.filterDateFrom : _iso(_after!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(after: false),
                    child: Text(
                      _before == null ? l.filterDateTo : _iso(_before!),
                    ),
                  ),
                ),
              ],
            ),
            if (_allTags.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: Text(l.filterTags)),
              Wrap(
                spacing: 6,
                children: _allTags
                    .map(
                      (t) => FilterChip(
                        label: Text(t.name),
                        selected: _tags.contains(t.name),
                        onSelected: (sel) => setState(
                          () => sel ? _tags.add(t.name) : _tags.remove(t.name),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: Text(l.filterSize)),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _sizeOp,
                    decoration: const InputDecoration(isDense: true),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: '>',
                        child: Text(l.filterSizeGreater),
                      ),
                      DropdownMenuItem<String>(
                        value: '<',
                        child: Text(l.filterSizeLess),
                      ),
                    ],
                    onChanged: (v) => setState(() => _sizeOp = v ?? '>'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _sizeValue,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _sizeUnit,
                    decoration: const InputDecoration(isDense: true),
                    items: _sizeUnits.keys
                        .map(
                          (u) => DropdownMenuItem<String>(
                            value: u,
                            child: Text(u),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _sizeUnit = v ?? 'MB'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _field(_account, l.filterAccount, Icons.account_tree_outlined),
            const SizedBox(height: 16),
            FilledButton(onPressed: _apply, child: Text(l.actionApply)),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: c,
          autocorrect: false,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        ),
      );
}
