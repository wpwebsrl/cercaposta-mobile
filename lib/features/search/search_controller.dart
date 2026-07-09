import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/auth/auth_controller.dart';
import '../../shared/models/search.dart';

/// One shared-folder scope entry: a share plus the path inside it.
class SharedScopeEntry {
  const SharedScopeEntry({required this.shareId, required this.path});
  final String shareId;
  final String path;
}

/// Folder the search is scoped to (Outlook-style drawer selection).
/// null in the provider means "all folders" — which server-side means EVERYTHING
/// the user can see: own archive + every received share (docs/condivisione.md).
/// A scope with [shared] set points into other users' archives: a single shared
/// folder, or a whole owner branch (all the folders that user shared).
class FolderScope {
  const FolderScope({
    required this.path,
    required this.name,
    this.shared,
    this.ownerLabel,
  });

  final String path;
  final String name;
  final List<SharedScopeEntry>? shared;
  final String? ownerLabel;

  bool get isShared => shared != null && shared!.isNotEmpty;

  /// Stable identity for selection compare (drawer highlight, no-op re-select).
  String get key => isShared
      ? 'shared:${shared!.map((e) => '${e.shareId}@${e.path}').join('|')}'
      : 'own:$path';
}

class FolderScopeController extends Notifier<FolderScope?> {
  @override
  FolderScope? build() {
    // Reset on logout/user switch/server switch: a stale scope would silently
    // filter the next user's searches with the previous user's folder path.
    ref.watch(sessionKeyProvider);
    return null;
  }

  void set(FolderScope? scope) => state = scope;
}

final folderScopeProvider =
    NotifierProvider<FolderScopeController, FolderScope?>(
      FolderScopeController.new,
    );

/// Merge the drawer scope into the parsed filters. The scope, when set, WINS
/// over any `cartella:` operator typed in the query, so the scope bar in the
/// app bar is always truthful. With no scope ("all folders") typed operators
/// pass through untouched. Server-side `folder_ancestors` semantics: a folder
/// always includes its descendants. A SHARED scope becomes filters.shared
/// (share_id + path) and drops any own-folder filter: shared content is only
/// ever searched under an explicit scope, never mixed into the default view.
Map<String, dynamic> applyFolderScope(
  Map<String, dynamic> filters,
  FolderScope? scope,
) {
  if (scope == null) return filters;
  if (scope.isShared) {
    final out = <String, dynamic>{
      ...filters,
      'shared': <Map<String, dynamic>>[
        for (final e in scope.shared!)
          <String, dynamic>{'share_id': e.shareId, 'path': e.path},
      ],
    };
    out.remove('folder');
    return out;
  }
  return <String, dynamic>{
    ...filters,
    'folder': <String>[scope.path],
  };
}

class SearchState {
  const SearchState({
    this.loading = false,
    this.loadingMore = false,
    this.hits = const <SearchHit>[],
    this.total = 0,
    this.cursor,
    this.finished = false,
    this.error,
    this.hasSearched = false,
    this.effectiveFolders = const <String>[],
    this.loadMoreFailed = false,
  });

  final bool loading;
  final bool loadingMore;
  final List<SearchHit> hits;
  final int total;
  final List<dynamic>? cursor;
  final bool finished;
  final Object? error;
  final bool hasSearched;

  /// The last loadMore() hit a network error: the list tail shows a retry row
  /// instead of silently stopping pagination (which reads as "no more results").
  final bool loadMoreFailed;

  /// Folder paths the CURRENT results are restricted to (scope or typed
  /// `cartella:` operators): the scope bar uses this to never lie.
  final List<String> effectiveFolders;

  SearchState copyWith({
    bool? loading,
    bool? loadingMore,
    List<SearchHit>? hits,
    int? total,
    List<dynamic>? cursor,
    bool? finished,
    Object? error,
    bool? hasSearched,
    List<String>? effectiveFolders,
    bool? loadMoreFailed,
  }) => SearchState(
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    hits: hits ?? this.hits,
    total: total ?? this.total,
    cursor: cursor ?? this.cursor,
    finished: finished ?? this.finished,
    error: error,
    hasSearched: hasSearched ?? this.hasSearched,
    effectiveFolders: effectiveFolders ?? this.effectiveFolders,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

class SearchController extends Notifier<SearchState> {
  String _text = '';
  Map<String, dynamic> _filters = const <String, dynamic>{};
  String _sort = 'relevance';
  // Bumped on every new search: in-flight pages of a SUPERSEDED query are dropped
  // instead of being mixed into the new result list.
  int _generation = 0;
  static const _pageSize = 25;

  @override
  SearchState build() {
    // Reset on logout/user switch/server switch so user B never sees user A's
    // results; the generation bump also drops any of A's in-flight responses.
    ref.watch(sessionKeyProvider);
    _generation++;
    _text = '';
    _filters = const <String, dynamic>{};
    return const SearchState();
  }

  Future<void> search(String raw, {String sort = 'relevance'}) async {
    final gen = ++_generation;
    state = const SearchState(loading: true, hasSearched: true);
    final api = ref.read(searchApiProvider);
    try {
      final parsed = await api.parse(raw);
      if (gen != _generation) return;
      _text = parsed.text;
      // Effective filters are frozen here so loadMore() paginates the SAME
      // query even if the drawer scope changes mid-scroll (a change re-runs
      // search() anyway, bumping the generation).
      final scope = ref.read(folderScopeProvider);
      _filters = applyFolderScope(parsed.filters, scope);
      _sort = sort;
      final res = await api.search(
        text: _text,
        filters: _filters,
        sort: _sort,
        size: _pageSize,
      );
      if (gen != _generation) return;
      final folders = _filters['folder'];
      state = SearchState(
        hits: res.hits,
        total: res.total,
        cursor: res.hits.isNotEmpty ? res.hits.last.sort : null,
        finished: res.hits.isEmpty || res.hits.length >= res.total,
        hasSearched: true,
        // A shared scope restricts to its path too: the scope bar must not lie.
        effectiveFolders: folders is List
            ? folders.whereType<String>().toList()
            : (scope?.isShared ?? false)
            ? <String>[scope!.path]
            : const <String>[],
      );
    } on Object catch (e) {
      if (gen != _generation) return;
      state = SearchState(error: e, hasSearched: true);
    }
  }

  Future<void> loadMore() async {
    if (state.loading ||
        state.loadingMore ||
        state.finished ||
        state.cursor == null) {
      return;
    }
    final gen = _generation;
    state = state.copyWith(loadingMore: true, loadMoreFailed: false);
    try {
      final res = await ref
          .read(searchApiProvider)
          .search(
            text: _text,
            filters: _filters,
            sort: _sort,
            size: _pageSize,
            searchAfter: state.cursor,
          );
      if (gen != _generation) return; // a newer search superseded this page
      final hits = <SearchHit>[...state.hits, ...res.hits];
      state = state.copyWith(
        loadingMore: false,
        hits: hits,
        total: res.total, // the index may have changed between pages
        cursor: res.hits.isNotEmpty ? res.hits.last.sort : state.cursor,
        finished: res.hits.isEmpty || hits.length >= res.total,
      );
    } on Object {
      if (gen != _generation) return;
      // Don't mark finished on a transient error: surface a retry affordance so
      // pagination can resume, instead of looking like the results ran out.
      state = state.copyWith(loadingMore: false, loadMoreFailed: true);
    }
  }
}

final searchProvider = NotifierProvider<SearchController, SearchState>(
  SearchController.new,
);
