import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/features/search/folder_drawer.dart';
import 'package:cercaposta/features/search/search_controller.dart';
import 'package:cercaposta/shared/models/taxonomy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FolderNode _node(
  String path, {
  int count = 0,
  List<FolderNode> children = const [],
}) => FolderNode(
  name: path.split('/').last,
  path: path,
  count: count,
  children: children,
);

final _tree = <FolderNode>[
  _node(
    'Archivio',
    count: 10,
    children: <FolderNode>[
      _node('Archivio/Posta in arrivo', count: 7),
      _node(
        'Archivio/Clienti',
        count: 3,
        children: <FolderNode>[_node('Archivio/Clienti/Rossi', count: 1)],
      ),
    ],
  ),
  _node('Spedite', count: 2),
];

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('applyFolderScope', () {
    test('no scope leaves filters untouched', () {
      final f = <String, dynamic>{'from': 'a@b.it'};
      expect(applyFolderScope(f, null), same(f));
    });

    test('scope is injected when the query has no folder operator', () {
      final out = applyFolderScope(
        <String, dynamic>{},
        const FolderScope(path: 'Archivio/Clienti', name: 'Clienti'),
      );
      expect(out['folder'], <String>['Archivio/Clienti']);
    });

    test('the drawer scope wins over an explicit cartella: operator', () {
      // The scope bar must always be truthful: when a scope is set it
      // overrides folder operators typed in the query.
      final f = <String, dynamic>{
        'folder': <String>['Spedite'],
      };
      expect(
        applyFolderScope(
          f,
          const FolderScope(path: 'Archivio', name: 'Archivio'),
        )['folder'],
        <String>['Archivio'],
      );
    });
  });

  group('FolderTree', () {
    testWidgets('children are hidden until the parent is expanded', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(FolderTree(nodes: _tree, selectedPath: null, onSelect: (_) {})),
      );
      expect(find.text('Archivio'), findsOneWidget);
      expect(find.text('Spedite'), findsOneWidget);
      expect(find.text('Posta in arrivo'), findsNothing);

      await tester.tap(find.byKey(const ValueKey<String>('expand-Archivio')));
      await tester.pump();
      expect(find.text('Posta in arrivo'), findsOneWidget);
      expect(find.text('Clienti'), findsOneWidget);
      expect(find.text('Rossi'), findsNothing); // grandchild still collapsed
    });

    testWidgets('tapping a folder reports the node', (tester) async {
      FolderNode? picked;
      await tester.pumpWidget(
        _wrap(
          FolderTree(
            nodes: _tree,
            selectedPath: null,
            onSelect: (n) => picked = n,
          ),
        ),
      );
      await tester.tap(find.text('Spedite'));
      expect(picked?.path, 'Spedite');
    });

    testWidgets('ancestors of the selected folder start expanded', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          FolderTree(
            nodes: _tree,
            selectedPath: 'Archivio/Clienti/Rossi',
            onSelect: (_) {},
          ),
        ),
      );
      // Both "Archivio" and "Clienti" must be expanded for the selection to show.
      expect(find.text('Rossi'), findsOneWidget);
    });
  });
}
