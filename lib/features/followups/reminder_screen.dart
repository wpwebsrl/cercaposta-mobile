import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/models/followup.dart';
import '../../shared/widgets/snack.dart';
import 'delta_html.dart';
import 'reminder_mailto.dart';
import 'reminder_preview_screen.dart';

/// «Prepara sollecito» (WP4.3 / solleciti v2-v3, parity with the desktop dialog):
/// the analysis model drafts the MESSAGE; the user edits it with basic formatting
/// (bold/italic/underline/strike/link/lists) via flutter_quill. The signature /
/// AI-disclosure / quoted original are appended by the server. The user then SENDS
/// it directly from the origin account via «Invia da Cerca posta», or opens it in
/// their own mail app (mailto), or confirms «l'ho inviato».
class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key, required this.item});

  final FollowupItem item;

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  final _subject = TextEditingController();
  final _instructions = TextEditingController();
  final _quill = QuillController.basic();
  final _editorFocus = FocusNode();
  final _editorScroll = ScrollController();

  String _register = ''; // '' | tu | lei
  String _language = ''; // '' | it | en
  bool?
  _includeOriginal; // null until the first draft resolves, then user-driven
  ReminderDraft? _draft;
  bool _loadingDraft = true;
  Object? _draftError;
  bool _sending = false;
  String? _sentFrom; // set once sent → green confirmation, then close
  int _draftSeq = 0; // only the latest regenerate wins

  @override
  void initState() {
    super.initState();
    _runDraft();
  }

  @override
  void dispose() {
    _subject.dispose();
    _instructions.dispose();
    _quill.dispose();
    _editorFocus.dispose();
    _editorScroll.dispose();
    super.dispose();
  }

  bool get _locked => _loadingDraft || _sentFrom != null;

  Future<void> _runDraft() async {
    _draftSeq++;
    final seq = _draftSeq;
    setState(() {
      _loadingDraft = true;
      _draftError = null;
    });
    try {
      final draft = await ref
          .read(followupApiProvider)
          .draftReminder(
            widget.item.id,
            instructions: _instructions.text.trim(),
            register: _register,
            language: _language,
            includeOriginal: _includeOriginal,
          );
      if (!mounted || seq != _draftSeq) return;
      setState(() {
        _draft = draft;
        _subject.text = draft.subject;
        _includeOriginal ??= draft.includeOriginal;
        _loadingDraft = false;
      });
      _seedEditor(draft.body);
    } on Object catch (e) {
      if (!mounted || seq != _draftSeq) return;
      setState(() {
        _loadingDraft = false;
        _draftError = e;
      });
    }
  }

  /// Seed the editor with the LLM's plain message; the user formats on top. A fresh
  /// draft re-seeds it (Document must end with a newline).
  void _seedEditor(String text) {
    final t = text.endsWith('\n') ? text : '$text\n';
    _quill.document = Document.fromDelta(Delta()..insert(t));
  }

  String _bodyText() => _quill.document.toPlainText().trimRight();
  String _bodyHtml() {
    final text = _bodyText();
    // Empty editor → empty HTML, so the server composes from the text core.
    return text.trim().isEmpty ? '' : deltaToHtml(_quill.document.toDelta());
  }

  Future<void> _remember() async {
    final l = AppLocalizations.of(context)!;
    if (_register.isEmpty) return;
    try {
      await ref
          .read(followupApiProvider)
          .contactRegister(widget.item.counterpartAddress, _register);
      if (mounted) showSnack(context, l.reminderRemembered);
    } on Object catch (e) {
      if (mounted) showSnack(context, localizeApiError(l, e), error: true);
    }
  }

  void _openPreview() {
    final text = _bodyText();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReminderPreviewScreen(
          followupId: widget.item.id,
          item: widget.item,
          subject: _subject.text,
          body: text,
          bodyHtml: text.trim().isEmpty ? '' : _bodyHtml(),
          includeOriginal: _includeOriginal,
        ),
      ),
    );
  }

  Future<void> _sendNow() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _sending = true);
    try {
      final from = await ref
          .read(followupApiProvider)
          .sendReminder(
            widget.item.id,
            subject: _subject.text,
            body: _bodyText(),
            bodyHtml: _bodyHtml(),
            includeOriginal: _includeOriginal,
          );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sentFrom = from;
      });
      // Leave the green confirmation up for a beat, then return true so the list reloads.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) context.pop(true);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      showSnack(context, localizeApiError(l, e), error: true);
    }
  }

  Future<void> _openMailApp() async {
    final l = AppLocalizations.of(context)!;
    final draft = _draft;
    if (draft == null) return;
    final url = reminderMailtoUrl(
      address: widget.item.counterpartAddress,
      subject: _subject.text,
      prefix: draft.reminderPrefix,
      body: _bodyText(),
      suffix: draft.reminderSuffix,
    );
    try {
      final ok = await launchUrl(Uri.parse(url));
      if (!ok && mounted) showSnack(context, l.reminderMailError, error: true);
    } on Object {
      if (mounted) showSnack(context, l.reminderMailError, error: true);
    }
  }

  Future<void> _markSent() async {
    final l = AppLocalizations.of(context)!;
    try {
      await ref.read(followupApiProvider).markReminded(widget.item.id);
      if (mounted) context.pop(true);
    } on Object catch (e) {
      if (mounted) showSnack(context, localizeApiError(l, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final draft = _draft;
    return Scaffold(
      appBar: AppBar(title: Text(l.reminderTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
        children: <Widget>[
          _recipient(),
          const SizedBox(height: 8),
          _statusLine(l),
          const SizedBox(height: 8),
          TextField(
            controller: _subject,
            enabled: !_locked,
            decoration: InputDecoration(labelText: l.reminderSubject),
          ),
          const SizedBox(height: 12),
          _registerRow(l, draft),
          const SizedBox(height: 10),
          _languageRow(l),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l.reminderIncludeOriginal),
            value: _includeOriginal ?? false,
            onChanged: _locked
                ? null
                : (v) => setState(() => _includeOriginal = v),
          ),
          const SizedBox(height: 4),
          _regenerateRow(l),
          const SizedBox(height: 14),
          Text(
            l.reminderMessage,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          _editor(l),
          const SizedBox(height: 8),
          Text(
            l.reminderAppendedNote,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (draft?.sendAvailable ?? false) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              l.reminderSendFromNote(draft!.sendFrom),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ..._actions(l, draft),
        ],
      ),
    );
  }

  Widget _recipient() {
    final item = widget.item;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.counterpartLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (item.counterpartName.isNotEmpty &&
            item.counterpartAddress.isNotEmpty)
          Text(
            item.counterpartAddress,
            style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
          ),
      ],
    );
  }

  Widget _statusLine(AppLocalizations l) {
    if (_sentFrom != null) {
      return Text(
        l.reminderSent(_sentFrom!),
        style: TextStyle(color: Colors.green.shade700),
      );
    }
    if (_loadingDraft) {
      return Row(
        children: <Widget>[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(l.reminderGenerating),
        ],
      );
    }
    if (_draftError != null) {
      return Text(
        _draftErrorText(l),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    return const SizedBox.shrink();
  }

  String _draftErrorText(AppLocalizations l) {
    final mapped = localizeApiError(l, _draftError!);
    // localizeApiError falls back to a bare "unexpected error" for unmapped codes;
    // prefer the dedicated draft message there.
    return mapped == l.errorGeneric ? l.reminderFailed : mapped;
  }

  /// Register picker. The segmented control (Auto/Tu/Lei) takes the full row width;
  /// the «remember for the contact» action lives on its own line below — sharing the
  /// first row with a long text button squeezed the segments into an unreadable mess
  /// on narrow phones. The «register used» hint fills the left of that second line.
  Widget _registerRow(AppLocalizations l, ReminderDraft? draft) {
    final used = draft?.registerUsed ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(l.reminderRegister),
            const SizedBox(width: 10),
            Expanded(
              child: SegmentedButton<String>(
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                showSelectedIcon: false,
                segments: <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: '',
                    label: Text(l.reminderRegisterAuto),
                  ),
                  ButtonSegment<String>(
                    value: 'tu',
                    label: Text(l.reminderRegisterTu),
                  ),
                  ButtonSegment<String>(
                    value: 'lei',
                    label: Text(l.reminderRegisterLei),
                  ),
                ],
                selected: <String>{_register},
                onSelectionChanged: _locked
                    ? null
                    : (s) => setState(() => _register = s.first),
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: used.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      l.reminderRegisterUsed(
                        _registerLabel(l, used),
                        _registerSourceLabel(l, draft!.registerSource),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: (_locked || _register.isEmpty) ? null : _remember,
              child: Text(l.reminderRememberContact),
            ),
          ],
        ),
      ],
    );
  }

  Widget _languageRow(AppLocalizations l) {
    return Row(
      children: <Widget>[
        Text(l.reminderLanguage),
        const SizedBox(width: 10),
        Expanded(
          child: SegmentedButton<String>(
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            showSelectedIcon: false,
            segments: <ButtonSegment<String>>[
              ButtonSegment<String>(
                value: '',
                label: Text(l.reminderLanguageAuto),
              ),
              const ButtonSegment<String>(value: 'it', label: Text('IT')),
              const ButtonSegment<String>(value: 'en', label: Text('EN')),
            ],
            selected: <String>{_language},
            onSelectionChanged: _locked
                ? null
                : (s) => setState(() => _language = s.first),
          ),
        ),
      ],
    );
  }

  Widget _regenerateRow(AppLocalizations l) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _instructions,
            enabled: !_locked,
            decoration: InputDecoration(
              isDense: true,
              hintText: l.reminderInstructionsHint,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: _locked ? null : _runDraft,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(l.reminderRegenerate),
        ),
      ],
    );
  }

  /// The rich-text editor for the MESSAGE. Wrapped in a forced-light theme so it
  /// reads like the outgoing mail (dark text on white) in both app themes, with a
  /// minimal toolbar matching the desktop/web surface.
  Widget _editor(AppLocalizations l) {
    final editorTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3CAE7E),
        brightness: Brightness.light,
      ),
    );
    return Theme(
      data: editorTheme,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            QuillSimpleToolbar(
              controller: _quill,
              config: const QuillSimpleToolbarConfig(
                multiRowsDisplay: false,
                showDividers: false,
                showFontFamily: false,
                showFontSize: false,
                showSmallButton: false,
                showInlineCode: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showClearFormat: false,
                showAlignmentButtons: false,
                showHeaderStyle: false,
                showListCheck: false,
                showCodeBlock: false,
                showQuote: false,
                showIndent: false,
                showUndo: false,
                showRedo: false,
                showSearchButton: false,
                showSubscript: false,
                showSuperscript: false,
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: true,
                showListBullets: true,
                showListNumbers: true,
                showLink: true,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: QuillEditor(
                controller: _quill,
                focusNode: _editorFocus,
                scrollController: _editorScroll,
                config: QuillEditorConfig(
                  placeholder: l.reminderMessage,
                  padding: const EdgeInsets.all(8),
                  minHeight: 160,
                  maxHeight: 320,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(AppLocalizations l, ReminderDraft? draft) {
    final ready = draft != null && !_locked;
    return <Widget>[
      if (draft?.sendAvailable ?? false)
        FilledButton.icon(
          onPressed: (ready && !_sending) ? _sendNow : null,
          icon: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(l.reminderSendNow),
        ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: ready ? _openPreview : null,
        icon: const Icon(Icons.visibility_outlined),
        label: Text(l.reminderPreview),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: ready ? _openMailApp : null,
        icon: const Icon(Icons.mail_outline),
        label: Text(l.reminderOpenMailApp),
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: ready ? _markSent : null,
        icon: const Icon(Icons.check),
        label: Text(l.reminderMarkSent),
      ),
    ];
  }

  String _registerLabel(AppLocalizations l, String reg) => switch (reg) {
    'tu' => l.reminderRegisterTu,
    'lei' => l.reminderRegisterLei,
    _ => l.reminderRegisterAuto,
  };

  String _registerSourceLabel(AppLocalizations l, String source) =>
      switch (source) {
        'manual' => l.reminderRegisterSourceManual,
        'contact' => l.reminderRegisterSourceContact,
        'detected' => l.reminderRegisterSourceDetected,
        _ => l.reminderRegisterSourceDefault,
      };
}
