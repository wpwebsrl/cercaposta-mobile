import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/models/message.dart';
import '../../shared/models/taxonomy.dart' as taxonomy;
import '../../shared/tag_colors.dart';
import '../../shared/widgets/snack.dart';

const _colors = <String>[
  'gray',
  'red',
  'orange',
  'yellow',
  'green',
  'teal',
  'blue',
  'purple',
  'pink',
];

Future<List<TagRef>?> showMessageTagsSheet(
  BuildContext context,
  WidgetRef ref, {
  required String messageId,
  required List<TagRef> selected,
}) => showModalBottomSheet<List<TagRef>>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _MessageTagsSheet(messageId: messageId, initial: selected),
);

class _MessageTagsSheet extends ConsumerStatefulWidget {
  const _MessageTagsSheet({required this.messageId, required this.initial});

  final String messageId;
  final List<TagRef> initial;

  @override
  ConsumerState<_MessageTagsSheet> createState() => _MessageTagsSheetState();
}

class _MessageTagsSheetState extends ConsumerState<_MessageTagsSheet> {
  var _tags = const <taxonomy.TagInfo>[];
  late var _selected = <String>{...widget.initial.map((tag) => tag.id)};
  var _loading = true;
  String? _busy;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final tags = await ref.read(taxonomyApiProvider).tags();
      if (mounted) setState(() => _tags = tags);
    } on Object catch (error) {
      if (mounted) {
        showSnack(
          context,
          localizeApiError(AppLocalizations.of(context)!, error),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(taxonomy.TagInfo tag, bool selected) async {
    setState(() => _busy = tag.id);
    try {
      final result = selected
          ? await ref
                .read(taxonomyApiProvider)
                .addMessageTag(widget.messageId, tag.id)
          : await ref
                .read(taxonomyApiProvider)
                .removeMessageTag(widget.messageId, tag.id);
      if (!mounted) return;
      setState(() => _selected = result.map((item) => item.id).toSet());
      ref.invalidate(tagColorsProvider);
    } on Object catch (error) {
      if (mounted) {
        showSnack(
          context,
          localizeApiError(AppLocalizations.of(context)!, error),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _edit([taxonomy.TagInfo? tag]) async {
    final edited = await _showTagEditor(context, ref, tag);
    if (edited == null || !mounted) return;
    await _reload();
    ref.invalidate(tagColorsProvider);
  }

  Future<void> _delete(taxonomy.TagInfo tag) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.tagsDeleteTitle),
        content: Text(l.tagsDeleteConfirm(tag.name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.tagsDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(taxonomyApiProvider).deleteTag(tag.id);
      if (!mounted) return;
      setState(() {
        _tags = _tags.where((item) => item.id != tag.id).toList();
        _selected.remove(tag.id);
      });
      ref.invalidate(tagColorsProvider);
    } on Object catch (error) {
      if (mounted) showSnack(context, localizeApiError(l, error), error: true);
    }
  }

  List<TagRef> get _result => _tags
      .where((tag) => _selected.contains(tag.id))
      .map((tag) => TagRef(id: tag.id, name: tag.name, color: tag.color))
      .toList();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text(l.tagsTitle),
              subtitle: Text(l.tagsAssignHint),
              trailing: IconButton(
                tooltip: l.tagsCreate,
                onPressed: _busy == null ? _edit : null,
                icon: const Icon(Icons.add),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _tags.isEmpty
                  ? Center(child: Text(l.tagsEmpty))
                  : ListView.builder(
                      itemCount: _tags.length,
                      itemBuilder: (context, index) {
                        final tag = _tags[index];
                        return CheckboxListTile(
                          value: _selected.contains(tag.id),
                          onChanged: _busy == null
                              ? (value) => _toggle(tag, value ?? false)
                              : null,
                          secondary: _busy == tag.id
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 6,
                                  backgroundColor: tagColor(tag.color),
                                ),
                          title: Text(tag.name),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.only(left: 8),
                          // Editing and deletion remain separate from assignment.
                          subtitle: Row(
                            children: <Widget>[
                              TextButton(
                                onPressed: _busy == null
                                    ? () => _edit(tag)
                                    : null,
                                child: Text(l.tagsEdit),
                              ),
                              TextButton(
                                onPressed: _busy == null
                                    ? () => _delete(tag)
                                    : null,
                                child: Text(l.tagsDelete),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy == null
                      ? () => Navigator.pop(context, _result)
                      : null,
                  child: Text(l.actionDone),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<taxonomy.TagInfo?> _showTagEditor(
  BuildContext context,
  WidgetRef ref,
  taxonomy.TagInfo? tag,
) async {
  final l = AppLocalizations.of(context)!;
  final name = TextEditingController(text: tag?.name ?? '');
  var color = tag?.color ?? 'gray';
  var saving = false;
  final result = await showDialog<taxonomy.TagInfo>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(tag == null ? l.tagsCreateTitle : l.tagsEditTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: name,
              autofocus: true,
              maxLength: 120,
              enabled: !saving,
              decoration: InputDecoration(labelText: l.tagsName),
            ),
            Wrap(
              spacing: 8,
              children: _colors
                  .map(
                    (value) => ChoiceChip(
                      selected: color == value,
                      showCheckmark: color == value,
                      avatar: CircleAvatar(
                        radius: 7,
                        backgroundColor: tagColor(value),
                      ),
                      label: const SizedBox.shrink(),
                      onSelected: saving
                          ? null
                          : (_) => setState(() => color = value),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: saving || name.text.trim().isEmpty
                ? null
                : () async {
                    setState(() => saving = true);
                    try {
                      final saved = tag == null
                          ? await ref
                                .read(taxonomyApiProvider)
                                .createTag(name.text.trim(), color)
                          : await ref
                                .read(taxonomyApiProvider)
                                .updateTag(
                                  tag.id,
                                  name: name.text.trim(),
                                  color: color,
                                );
                      if (context.mounted) Navigator.pop(context, saved);
                    } on Object catch (error) {
                      if (!context.mounted) return;
                      setState(() => saving = false);
                      showSnack(
                        context,
                        localizeApiError(l, error),
                        error: true,
                      );
                    }
                  },
            child: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.actionSave),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  return result;
}
