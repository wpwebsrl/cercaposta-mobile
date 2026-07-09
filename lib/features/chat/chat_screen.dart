import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/models/chat.dart';
import '../../shared/widgets/snack.dart';
import 'chat_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(chatProvider.notifier).checkStatus());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    ref.read(chatProvider.notifier).send(text);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Follow the stream as tokens arrive, but only if the user is already near the
  /// bottom — don't yank the view while they scroll up to read earlier messages.
  void _maybeAutoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position;
      if (pos.maxScrollExtent - pos.pixels < 160) {
        _scroll.jumpTo(pos.maxScrollExtent);
      }
    });
  }

  Future<void> _showHistory() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => const _HistorySheet(),
    );
  }

  String _phaseLabel(AppLocalizations l, String? phase) => switch (phase) {
    'understanding' => l.chatPhaseUnderstanding,
    'searching' => l.chatPhaseSearching,
    'embedding' => l.chatPhaseEmbedding,
    'reranking' => l.chatPhaseReranking,
    'generating' => l.chatPhaseGenerating,
    _ => l.chatPhaseUnderstanding,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(chatProvider);
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (next.streaming ||
          next.messages.length != (prev?.messages.length ?? 0)) {
        _maybeAutoScroll();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l.chatTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l.chatHistory,
            onPressed: state.streaming ? null : _showHistory,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: l.chatNew,
            onPressed: state.streaming
                ? null
                : ref.read(chatProvider.notifier).newConversation,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: _body(context, l, state),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l, ChatState state) {
    if (state.available == false) {
      return _centered(
        context,
        Icons.smart_toy_outlined,
        state.aiEnabled == false ? l.chatDisabled : l.chatNotConfigured,
      );
    }
    // Status check failed on the network (not "server says off"): let the user retry.
    if (state.available == null && state.statusFailed) {
      return _centered(
        context,
        Icons.wifi_off_outlined,
        l.chatStatusError,
        action: FilledButton(
          onPressed: () => ref.read(chatProvider.notifier).checkStatus(),
          child: Text(l.actionRetry),
        ),
      );
    }
    return Column(
      children: <Widget>[
        Expanded(child: _messages(context, l, state)),
        if (state.streaming) _phaseBar(context, l, state.phase),
        if (state.embeddingFailed) _embeddingWarn(context, l),
        if (state.error != null) _errorBar(context, l, state.error!),
        _inputBar(context, l, state.streaming),
      ],
    );
  }

  Widget _centered(
    BuildContext context,
    IconData icon,
    String text, {
    Widget? action,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...<Widget>[const SizedBox(height: 16), action],
        ],
      ),
    ),
  );

  Widget _messages(BuildContext context, AppLocalizations l, ChatState state) {
    if (state.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l.chatHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      itemCount: state.messages.length,
      itemBuilder: (context, i) => _bubble(context, state.messages[i]),
    );
  }

  Widget _bubble(BuildContext context, ChatMessage m) {
    final theme = Theme.of(context);
    final isUser = m.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SelectableText(m.content.isEmpty ? '…' : m.content),
            if (m.citations.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: m.citations
                    .map(
                      (c) => ActionChip(
                        label: Text(
                          '[${c.n}] ${c.subject.isEmpty ? c.fromLabel : c.subject}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context.push('/message/${c.id}'),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _phaseBar(BuildContext context, AppLocalizations l, String? phase) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: <Widget>[
            const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              _phaseLabel(l, phase),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );

  Widget _embeddingWarn(BuildContext context, AppLocalizations l) => Container(
    width: double.infinity,
    color: Theme.of(context).colorScheme.tertiaryContainer,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Text(
      l.chatEmbeddingFailed,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );

  Widget _errorBar(BuildContext context, AppLocalizations l, Object error) =>
      Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.errorContainer,
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                localizeApiError(l, error),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref.read(chatProvider.notifier).retryLast(),
              child: Text(l.actionRetry),
            ),
          ],
        ),
      );

  Widget _inputBar(BuildContext context, AppLocalizations l, bool streaming) =>
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => streaming ? null : _send(),
                  decoration: InputDecoration(hintText: l.chatHint),
                ),
              ),
              const SizedBox(width: 4),
              if (streaming)
                IconButton.filled(
                  onPressed: () => ref.read(chatProvider.notifier).stop(),
                  icon: const Icon(Icons.stop),
                  tooltip: l.chatStop,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                )
              else
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                  tooltip: l.chatSend,
                ),
            ],
          ),
        ),
      );
}

/// Conversation history sheet: open, rename or delete a saved conversation.
/// Stateful so a rename/delete refreshes the list in place.
class _HistorySheet extends ConsumerStatefulWidget {
  const _HistorySheet();

  @override
  ConsumerState<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends ConsumerState<_HistorySheet> {
  late Future<List<ConversationInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(chatApiProvider).conversations();
  }

  void _reload() =>
      setState(() => _future = ref.read(chatApiProvider).conversations());

  Future<void> _rename(ConversationInfo c) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: c.title);
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.chatRenameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l.actionSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty || title == c.title) return;
    try {
      await ref.read(chatProvider.notifier).renameConversation(c.id, title);
      _reload();
    } on Object catch (e) {
      if (mounted) showSnack(context, localizeApiError(l, e), error: true);
    }
  }

  Future<void> _delete(ConversationInfo c) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.chatDelete),
        content: Text(l.chatDeleteConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.actionConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(chatProvider.notifier).deleteConversation(c.id);
      _reload();
    } on Object catch (e) {
      if (mounted) showSnack(context, localizeApiError(l, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = ref.watch(authProvider).user?.locale ?? 'it-IT';
    return FutureBuilder<List<ConversationInfo>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text(localizeApiError(l, snap.error!))),
          );
        }
        final items = snap.data ?? const <ConversationInfo>[];
        if (items.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(child: Text(l.chatHistoryEmpty)),
          );
        }
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final c = items[i];
              return ListTile(
                leading: Icon(
                  c.pinned ? Icons.push_pin : Icons.chat_bubble_outline,
                  size: 20,
                ),
                title: Text(
                  c.title.isEmpty ? '—' : c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(formatDateShort(c.lastMessageAt, locale)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(chatProvider.notifier).loadConversation(c.id);
                },
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => v == 'rename' ? _rename(c) : _delete(c),
                  itemBuilder: (ctx) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'rename',
                      child: Text(l.chatRename),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(l.chatDelete),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
