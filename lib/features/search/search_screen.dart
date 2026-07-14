import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/api/error_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/live/live_refresh.dart';
import '../../shared/format.dart';
import '../../shared/models/search.dart';
import '../../shared/tag_colors.dart';
import '../../shared/widgets/snack.dart';
import '../home/home_tab.dart';
import 'filter_sheet.dart';
import 'folder_drawer.dart';
import 'search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  final _scroll = ScrollController();
  final _speech = SpeechToText();
  bool _listening = false;
  bool _hasQueryText = false;
  // Result order: newest-first by default (like web/desktop). 'relevance' | 'date_desc' | 'date_asc'.
  String _sort = 'date_desc';
  // liveArchiveRev at the last search: when the live channel reports a higher one, the archive
  // changed under the current results → offer a «new results» refresh (never auto-rerun on mobile).
  int _baselineRev = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _query.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    // Stop a live recognition session: the mic must not stay open (and its
    // callbacks must not touch a disposed controller) after leaving the tab.
    _speech.stop();
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      ref.read(searchProvider.notifier).loadMore();
    }
  }

  void _onQueryChanged() {
    final has = _query.text.isNotEmpty;
    if (has != _hasQueryText) setState(() => _hasQueryText = has);
  }

  /// Every search goes through here so the chosen [_sort] is always applied and the «new
  /// results» baseline is re-armed (the current results are, by definition, up to date).
  Future<void> _runSearch() {
    _baselineRev = ref.read(liveArchiveRevProvider);
    return ref.read(searchProvider.notifier).search(_query.text, sort: _sort);
  }

  void _run() {
    FocusScope.of(context).unfocus();
    _runSearch();
  }

  /// Clear button (×): empty the omnibox and re-run so results reset to the
  /// current folder scope immediately, without pressing search.
  void _clearQuery() {
    _query.clear();
    FocusScope.of(context).unfocus();
    _runSearch();
  }

  void _setSort(String sort) {
    if (sort == _sort) return;
    setState(() => _sort = sort);
    _runSearch();
  }

  /// Pull-to-refresh: reload the folders/shares AND re-run the current query, so a manual pull
  /// always shows the freshest data (docs/eventi-live.md).
  Future<void> _pullRefresh() async {
    refreshFolders(ref);
    await _runSearch();
  }

  /// Stop a live mic session when leaving the search tab: the IndexedStack keeps
  /// this screen alive, so dispose() won't fire on a tab switch.
  void _stopListeningIfActive() {
    if (_listening) {
      _speech.stop();
      setState(() => _listening = false);
    }
  }

  Future<void> _toggleVoice() async {
    final l = AppLocalizations.of(context)!;
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() => _listening = false);
          final denied =
              e.errorMsg.contains('permission') ||
              e.errorMsg.contains('not-allowed');
          showSnack(
            context,
            denied ? l.searchVoicePermission : l.searchVoiceUnavailable,
            error: true,
          );
        }
      },
    );
    if (!available) {
      if (mounted) showSnack(context, l.searchVoiceUnavailable, error: true);
      return;
    }
    final lang = ref.read(authProvider).user?.language ?? 'it';
    setState(() => _listening = true);
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: lang == 'en' ? 'en_US' : 'it_IT',
      ),
      onResult: (r) {
        _query.text = r.recognizedWords;
        _query.selection = TextSelection.collapsed(offset: _query.text.length);
        if (r.finalResult) _run();
      },
    );
  }

  Future<void> _openFilters() async {
    final composed = await showFilterSheet(context, _query.text);
    if (composed != null) {
      _query.text = composed;
      _run();
    }
  }

  /// Drawer selection: scope the search to [scope] (null = all folders) and
  /// re-run the current query. With an empty query the server lists the
  /// folder's mail by date (match_all), so picking a folder always shows
  /// something — the Outlook mental model.
  void _selectFolder(FolderScope? scope) {
    final current = ref.read(folderScopeProvider);
    if (scope?.key == current?.key) return;
    ref.read(folderScopeProvider.notifier).set(scope);
    _runSearch();
  }

  /// The scope bar never lies: drawer scope when set (it wins server-side),
  /// otherwise any `cartella:` operators typed in the query, else "all".
  /// A shared scope shows the owner too («Mario · Fatture»); a whole owner
  /// branch shows just their name.
  String _scopeLabel(
    AppLocalizations l,
    FolderScope? scope,
    SearchState state,
  ) {
    if (scope != null) {
      final owner = scope.ownerLabel;
      if (scope.isShared && owner != null && scope.name != owner) {
        return '$owner · ${scope.name}';
      }
      return scope.name;
    }
    final typed = state.effectiveFolders;
    if (typed.isEmpty) return l.foldersAll;
    if (typed.length == 1) return typed.first.split('/').last;
    return l.foldersMultiple(typed.length);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(searchProvider);
    final scope = ref.watch(folderScopeProvider);
    ref.listen<int>(homeTabProvider, (_, next) {
      if (next != 0) _stopListeningIfActive();
    });
    return Scaffold(
      drawer: FolderDrawer(selected: scope, onSelect: _selectFolder),
      appBar: AppBar(
        // The scope bar below is the drawer affordance: no hamburger, the
        // omnibox keeps the full title width.
        automaticallyImplyLeading: false,
        titleSpacing: 10,
        // A curated rounded search pill (magnifier + clear), not a bare field: a
        // filled surface, soft outline, and a primary-tinted ring on focus.
        title: TextField(
          controller: _query,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _run(),
          style: TextStyle(fontSize: 15, color: cs.onSurface),
          decoration: InputDecoration(
            hintText: l.searchHint,
            hintStyle: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
            filled: true,
            fillColor: cs.surfaceContainerHigh,
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            suffixIcon: _hasQueryText
                ? IconButton(
                    tooltip: l.searchClear,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _clearQuery,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Builder(
            builder: (ctx) => InkWell(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      (scope?.isShared ?? false)
                          ? Icons.people_outline
                          : scope == null && state.effectiveFolders.isEmpty
                          ? Icons.all_inbox_outlined
                          : Icons.folder_outlined,
                      size: 16,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _scopeLabel(l, scope, state),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(ctx).textTheme.labelLarge,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l.searchVoice,
            onPressed: _toggleVoice,
            icon: Icon(
              _listening ? Icons.mic : Icons.mic_none,
              color: _listening ? Theme.of(context).colorScheme.error : null,
            ),
          ),
          IconButton(
            tooltip: l.searchFilters,
            onPressed: _openFilters,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: _body(context, l, state),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l, SearchState state) {
    if (state.loading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return _Centered(
        icon: Icons.error_outline,
        text: localizeApiError(l, state.error!),
        action: FilledButton(onPressed: _run, child: Text(l.actionRetry)),
      );
    }
    if (!state.hasSearched) {
      return _Centered(icon: Icons.search, text: l.searchEmptyPrompt);
    }
    if (state.hits.isEmpty) {
      // Still allow a pull-to-refresh over the empty state (a folder may have just filled).
      return RefreshIndicator(
        onRefresh: _pullRefresh,
        child: ListView(
          children: <Widget>[
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.6,
              child: _Centered(
                icon: Icons.inbox_outlined,
                text: l.searchNoResults,
              ),
            ),
          ],
        ),
      );
    }
    final locale = ref.watch(authProvider).user?.locale ?? 'it-IT';
    // The archive changed under the current results (live channel) → offer a manual refresh.
    final newResults = ref.watch(liveArchiveRevProvider) > _baselineRev;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l.searchResultsCount(state.total),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              _SortMenu(sort: _sort, onChanged: _setSort),
            ],
          ),
        ),
        if (newResults) _NewResultsBanner(onTap: _runSearch),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _pullRefresh,
            child: ListView.separated(
              controller: _scroll,
              itemCount: state.hits.length + (state.finished ? 0 : 1),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                if (i >= state.hits.length) {
                  if (state.loadMoreFailed) {
                    return InkWell(
                      onTap: () => ref.read(searchProvider.notifier).loadMore(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.refresh,
                              size: 18,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Flexible(child: Text(l.searchLoadMoreError)),
                          ],
                        ),
                      ),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _ResultTile(hit: state.hits[i], locale: locale);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Result-order menu (relevance / newest / oldest) shown on the results header row.
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onChanged});
  final String sort;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    String label(String s) => switch (s) {
      'date_desc' => l.sortNewest,
      'date_asc' => l.sortOldest,
      _ => l.sortRelevance,
    };
    return PopupMenuButton<String>(
      initialValue: sort,
      tooltip: l.sortTooltip,
      onSelected: onChanged,
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'relevance', child: Text(l.sortRelevance)),
        PopupMenuItem<String>(value: 'date_desc', child: Text(l.sortNewest)),
        PopupMenuItem<String>(value: 'date_asc', child: Text(l.sortOldest)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.swap_vert, size: 18),
            const SizedBox(width: 4),
            Text(label(sort), style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

/// Tappable «new results» banner: the archive changed while these results were on screen.
class _NewResultsBanner extends StatelessWidget {
  const _NewResultsBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.refresh, size: 16, color: cs.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                l.searchNewResults,
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends ConsumerWidget {
  const _ResultTile({required this.hit, required this.locale});
  final SearchHit hit;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final colors =
        ref.watch(tagColorsProvider).valueOrNull ?? const <String, TagInfo>{};
    return ListTile(
      title: Text(
        hit.subject.isEmpty ? '—' : hit.subject,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (hit.sharedOwnerName != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: Tooltip(
                    message: l.sharedFromLabel(hit.sharedOwnerName!),
                    child: Icon(
                      Icons.people_outline,
                      size: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  hit.fromLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (hit.date != null)
                Text(
                  formatDateTimeShort(hit.date, locale),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          if (hit.snippet.isNotEmpty)
            Text(
              hit.snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (hit.hasAttachments || hit.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Wrap(
                spacing: 6,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  if (hit.hasAttachments)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.attach_file, size: 13),
                        Text(
                          l.attachmentsCount(hit.attachmentCount),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  // Hits carry lowercased tag names: resolve to the real color and
                  // original casing via the session tag map (fallback to the raw name).
                  ...hit.tags.take(3).map((t) {
                    final info = colors[t.toLowerCase()];
                    return _MiniTag(
                      name: info?.name ?? t,
                      colorName: info?.color,
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
      onTap: () => context.push('/message/${hit.id}'),
    );
  }
}

/// A dense tag pill for the results list: a colored dot + the tag name. The dot
/// color comes from the session tag map (search hits carry only names).
class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.name, required this.colorName});
  final String name;
  final String? colorName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: tagColor(colorName ?? 'gray'),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(name, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...<Widget>[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
