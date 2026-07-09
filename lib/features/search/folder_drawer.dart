import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/models/taxonomy.dart';
import 'search_controller.dart';

/// Folder tree for the scope drawer; cached while the session lives (the
/// header offers a manual refresh — folders change when a sync runs). Watching
/// the session key drops the cache on logout/user switch/server switch, so a
/// new user never sees the previous user's folder names and counts.
final foldersTreeProvider = FutureProvider<FolderTreeResult>((ref) {
  ref.watch(sessionKeyProvider);
  return ref.watch(taxonomyApiProvider).folders();
});

/// Folders other users shared with this account (docs/condivisione.md) — the
/// «Shared with me» section of the drawer. Same session-scoped caching.
final sharesReceivedProvider = FutureProvider<List<ShareInfo>>((ref) {
  ref.watch(sessionKeyProvider);
  return ref.watch(taxonomyApiProvider).sharesReceived();
});

/// Lazy subtree of one share, fetched the first time its node is expanded.
final shareTreeProvider = FutureProvider.family<FolderTreeResult, String>((
  ref,
  shareId,
) {
  ref.watch(sessionKeyProvider);
  return ref.watch(taxonomyApiProvider).shareTree(shareId);
});

/// Outlook-style folder panel: slides in from the left without covering the
/// whole screen. The first entry restores "all folders" ([onSelect] gets null =
/// everything the user can see, own + shared); tapping a folder scopes the search
/// to that subtree. After the own tree come the per-OWNER branches: one row per
/// user who shared folders with this account, their folders beneath (read-only).
class FolderDrawer extends ConsumerWidget {
  const FolderDrawer({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final FolderScope? selected;
  final ValueChanged<FolderScope?> onSelect;

  String? get selectedPath =>
      (selected?.isShared ?? false) ? null : selected?.path;

  void _pick(BuildContext context, FolderScope? scope) {
    Navigator.pop(context); // close the drawer; the search re-runs behind it
    onSelect(scope);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final tree = ref.watch(foldersTreeProvider);
    final shares =
        ref.watch(sharesReceivedProvider).valueOrNull ?? const <ShareInfo>[];
    final sharedTotal = shares.fold<int>(0, (acc, s) => acc + (s.count ?? 0));
    final locale =
        ref.watch(authProvider.select((s) => s.user?.locale)) ?? 'it-IT';
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l.foldersTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: l.foldersRefresh,
                    onPressed: () => ref.invalidate(foldersTreeProvider),
                    icon: const Icon(Icons.refresh, size: 20),
                  ),
                ],
              ),
            ),
            FolderRow(
              icon: Icons.all_inbox_outlined,
              label: l.foldersAll,
              // Everything the user can see: own archive + every received share.
              count: (tree.valueOrNull?.total ?? 0) + sharedTotal,
              locale: locale,
              depth: 0,
              selected: selected == null,
              onTap: () => _pick(context, null),
            ),
            const Divider(height: 1),
            Expanded(
              // skipLoadingOnRefresh false: tapping retry after an error must
              // visibly switch to the spinner, not keep the stale error text.
              child: tree.when(
                skipLoadingOnRefresh: false,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _DrawerMessage(
                  text: localizeApiError(l, e),
                  action: TextButton(
                    onPressed: () => ref.invalidate(foldersTreeProvider),
                    child: Text(l.actionRetry),
                  ),
                ),
                data: (result) {
                  // Per-owner branches straight after the own folders: one row
                  // per user who shared, their folders beneath (real names).
                  final byOwner = <String, List<ShareInfo>>{};
                  for (final s in shares) {
                    byOwner
                        .putIfAbsent(s.ownerUsername, () => <ShareInfo>[])
                        .add(s);
                  }
                  final owners = byOwner.values.toList()
                    ..sort(
                      (a, b) => a.first.ownerDisplayName
                          .toLowerCase()
                          .compareTo(b.first.ownerDisplayName.toLowerCase()),
                    );
                  final trailing = <Widget>[
                    if (owners.isNotEmpty) const Divider(height: 1),
                    for (final ownerShares in owners)
                      OwnerBranchTile(
                        key: ValueKey<String>(
                          'owner-${ownerShares.first.ownerUsername}',
                        ),
                        shares: ownerShares,
                        selected: selected,
                        locale: locale,
                        onSelect: (scope) => _pick(context, scope),
                      ),
                  ];
                  if (result.roots.isEmpty && trailing.isEmpty) {
                    return _DrawerMessage(text: l.foldersEmpty);
                  }
                  return FolderTree(
                    nodes: result.roots,
                    selectedPath: selectedPath,
                    locale: locale,
                    onSelect: (n) =>
                        _pick(context, FolderScope(path: n.path, name: n.name)),
                    trailing: trailing,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One user who shared folders with me: a branch row with their name; tapping
/// it scopes the search to ALL their shares, the children are the shared
/// folders with their real names (subtrees load lazily, docs/condivisione.md).
class OwnerBranchTile extends ConsumerStatefulWidget {
  const OwnerBranchTile({
    super.key,
    required this.shares,
    required this.selected,
    required this.onSelect,
    this.locale = 'it-IT',
  });

  final List<ShareInfo> shares;
  final FolderScope? selected;
  final ValueChanged<FolderScope> onSelect;
  final String locale;

  @override
  ConsumerState<OwnerBranchTile> createState() => _OwnerBranchTileState();
}

class _OwnerBranchTileState extends ConsumerState<OwnerBranchTile> {
  bool _open = false;
  final Set<String> _openShares = <String>{};
  final Set<String> _expanded = <String>{};

  String get _ownerLabel => widget.shares.first.ownerDisplayName;

  FolderScope get _ownerScope => FolderScope(
    path: '',
    name: _ownerLabel,
    ownerLabel: _ownerLabel,
    shared: <SharedScopeEntry>[
      for (final s in widget.shares)
        SharedScopeEntry(shareId: s.id, path: s.folderPath),
    ],
  );

  FolderScope _scopeFor(ShareInfo share, String path, String name) =>
      FolderScope(
        path: path,
        name: name,
        ownerLabel: _ownerLabel,
        shared: <SharedScopeEntry>[
          SharedScopeEntry(shareId: share.id, path: path),
        ],
      );

  bool _isSelected(FolderScope scope) => widget.selected?.key == scope.key;

  Widget _expander({
    Key? key,
    required bool expanded,
    required VoidCallback onTap,
  }) => IconButton(
    key: key,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
    visualDensity: VisualDensity.compact,
    icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18),
    onPressed: onTap,
  );

  List<Widget> _nodeRows(ShareInfo share, List<FolderNode> nodes, int depth) {
    final rows = <Widget>[];
    for (final n in nodes) {
      final expanded = _expanded.contains('${share.id}:${n.path}');
      rows.add(
        FolderRow(
          key: ValueKey<String>('share-${share.id}-${n.path}'),
          icon: expanded && n.children.isNotEmpty
              ? Icons.folder_open_outlined
              : Icons.folder_outlined,
          label: n.name,
          count: n.count,
          locale: widget.locale,
          depth: depth,
          selected: _isSelected(_scopeFor(share, n.path, n.name)),
          onTap: () => widget.onSelect(_scopeFor(share, n.path, n.name)),
          expander: n.children.isEmpty
              ? null
              : _expander(
                  expanded: expanded,
                  onTap: () => setState(
                    () => expanded
                        ? _expanded.remove('${share.id}:${n.path}')
                        : _expanded.add('${share.id}:${n.path}'),
                  ),
                ),
        ),
      );
      if (expanded) rows.addAll(_nodeRows(share, n.children, depth + 1));
    }
    return rows;
  }

  Widget _shareRoot(ShareInfo share) {
    final open = _openShares.contains(share.id);
    final tree = open ? ref.watch(shareTreeProvider(share.id)) : null;
    final root = tree?.valueOrNull?.roots.firstOrNull;
    final rootScope = _scopeFor(share, share.folderPath, share.rootName);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FolderRow(
          key: ValueKey<String>('share-root-${share.id}'),
          icon: open ? Icons.folder_open_outlined : Icons.folder_outlined,
          label: share.rootName,
          count: root?.count ?? share.count ?? 0,
          locale: widget.locale,
          depth: 1,
          selected: _isSelected(rootScope),
          onTap: () => widget.onSelect(rootScope),
          expander: !share.includeSubtree
              ? null
              : _expander(
                  key: ValueKey<String>('share-expand-${share.id}'),
                  expanded: open,
                  onTap: () => setState(
                    () => open
                        ? _openShares.remove(share.id)
                        : _openShares.add(share.id),
                  ),
                ),
        ),
        if (open && tree != null)
          tree.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (result) {
              final children = result.roots.firstOrNull?.children ?? const [];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: _nodeRows(share, children, 2),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.shares.fold<int>(0, (acc, s) => acc + (s.count ?? 0));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FolderRow(
          icon: Icons.people_outline,
          label: _ownerLabel,
          count: count,
          locale: widget.locale,
          depth: 0,
          selected: _isSelected(_ownerScope),
          onTap: () => widget.onSelect(_ownerScope),
          expander: _expander(
            key: ValueKey<String>(
              'owner-expand-${widget.shares.first.ownerUsername}',
            ),
            expanded: _open,
            onTap: () => setState(() => _open = !_open),
          ),
        ),
        if (_open) ...widget.shares.map(_shareRoot),
      ],
    );
  }
}

/// Expandable folder tree. Public (instead of private to the drawer) so widget
/// tests can drive expansion/selection without network or Riverpod.
class FolderTree extends StatefulWidget {
  const FolderTree({
    super.key,
    required this.nodes,
    required this.selectedPath,
    required this.onSelect,
    this.locale = 'it-IT',
    this.trailing = const <Widget>[],
  });

  final List<FolderNode> nodes;
  final String? selectedPath;
  final ValueChanged<FolderNode> onSelect;
  final String locale;

  /// Extra rows appended after the own tree in the SAME scrollable (the
  /// «Shared with me» section) — one list, one scrollbar, Outlook-style.
  final List<Widget> trailing;

  @override
  State<FolderTree> createState() => _FolderTreeState();
}

class _FolderTreeState extends State<FolderTree> {
  final Set<String> _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    _expandToSelection(widget.nodes);
  }

  @override
  void didUpdateWidget(FolderTree old) {
    super.didUpdateWidget(old);
    // The drawer can stay mounted across opens: keep the selection visible
    // when it changed since the last build (expansion state is preserved).
    if (old.selectedPath != widget.selectedPath) {
      _expandToSelection(widget.nodes);
    }
  }

  /// Expand every ancestor of the selected folder so it is visible on open.
  /// Returns true if [nodes] (or a descendant) contains the selection.
  bool _expandToSelection(List<FolderNode> nodes) {
    for (final n in nodes) {
      if (n.path == widget.selectedPath) return true;
      if (_expandToSelection(n.children)) {
        _expanded.add(n.path);
        return true;
      }
    }
    return false;
  }

  List<(FolderNode, int)> _visible() {
    final rows = <(FolderNode, int)>[];
    void walk(List<FolderNode> nodes, int depth) {
      for (final n in nodes) {
        rows.add((n, depth));
        if (_expanded.contains(n.path)) walk(n.children, depth + 1);
      }
    }

    walk(widget.nodes, 0);
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = _visible();
    return ListView.builder(
      itemCount: rows.length + widget.trailing.length,
      itemBuilder: (context, i) {
        if (i >= rows.length) return widget.trailing[i - rows.length];
        final (node, depth) = rows[i];
        final expanded = _expanded.contains(node.path);
        return FolderRow(
          key: ValueKey<String>('folder-${node.path}'),
          icon: expanded && node.children.isNotEmpty
              ? Icons.folder_open_outlined
              : Icons.folder_outlined,
          label: node.name,
          count: node.count,
          locale: widget.locale,
          depth: depth + 1,
          selected: node.path == widget.selectedPath,
          onTap: () => widget.onSelect(node),
          expander: node.children.isEmpty
              ? null
              : IconButton(
                  key: ValueKey<String>('expand-${node.path}'),
                  tooltip: expanded ? l.foldersCollapse : l.foldersExpand,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  onPressed: () => setState(
                    () => expanded
                        ? _expanded.remove(node.path)
                        : _expanded.add(node.path),
                  ),
                ),
        );
      },
    );
  }
}

/// One dense row of the folder panel (32px, per the density rules).
class FolderRow extends StatelessWidget {
  const FolderRow({
    super.key,
    required this.icon,
    required this.label,
    required this.depth,
    required this.selected,
    required this.onTap,
    this.count = 0,
    this.locale = 'it-IT',
    this.expander,
  });

  final IconData icon;
  final String label;
  final int depth;
  final bool selected;
  final VoidCallback onTap;
  final int count;
  final String locale;
  final Widget? expander;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Indent capped so very deep trees keep the label readable instead of
    // pushing it off the ~304px drawer.
    final indent = 12.0 + math.min(depth, 6) * 14;
    return InkWell(
      onTap: onTap,
      child: Ink(
        color: selected ? scheme.secondaryContainer : null,
        child: Container(
          height: 32,
          padding: EdgeInsetsDirectional.only(start: indent, end: 4),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color: selected ? scheme.onSecondaryContainer : scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (count > 0)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6),
                  child: Text(
                    formatCount(count, locale),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected
                          ? scheme.onSecondaryContainer
                          : scheme.outline,
                    ),
                  ),
                ),
              if (expander != null) expander! else const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerMessage extends StatelessWidget {
  const _DrawerMessage({required this.text, this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...<Widget>[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}
