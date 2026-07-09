import 'package:cercaposta/features/search/search_controller.dart';
import 'package:cercaposta/shared/tag_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applyFolderScope: a set scope wins; null passes filters through', () {
    expect(
      applyFolderScope(<String, dynamic>{'from': 'x'}, null),
      <String, dynamic>{'from': 'x'},
    );
    // The drawer scope overrides any typed cartella: operator.
    expect(
      applyFolderScope(<String, dynamic>{
        'from': 'x',
        'folder': <String>['typed'],
      }, const FolderScope(path: 'scoped', name: 'Scoped')),
      <String, dynamic>{
        'from': 'x',
        'folder': <String>['scoped'],
      },
    );
  });

  test('applyFolderScope: a SHARED scope becomes filters.shared and drops '
      'any own-folder filter (docs/condivisione.md)', () {
    expect(
      applyFolderScope(
        <String, dynamic>{
          'from': 'x',
          'folder': <String>['typed'],
        },
        const FolderScope(
          path: 'Clienti/Fatture',
          name: 'Fatture',
          ownerLabel: 'Mario',
          shared: <SharedScopeEntry>[
            SharedScopeEntry(shareId: 'share-1', path: 'Clienti/Fatture'),
          ],
        ),
      ),
      <String, dynamic>{
        'from': 'x',
        'shared': <Map<String, dynamic>>[
          <String, dynamic>{'share_id': 'share-1', 'path': 'Clienti/Fatture'},
        ],
      },
    );
  });

  test('applyFolderScope: an OWNER branch scope carries every share of that '
      'user (one filters.shared entry per share)', () {
    final out = applyFolderScope(
      <String, dynamic>{},
      const FolderScope(
        path: '',
        name: 'Mario',
        ownerLabel: 'Mario',
        shared: <SharedScopeEntry>[
          SharedScopeEntry(shareId: 's1', path: 'Clienti/Fatture'),
          SharedScopeEntry(shareId: 's2', path: 'Progetti'),
        ],
      ),
    );
    expect(out['shared'], <Map<String, dynamic>>[
      <String, dynamic>{'share_id': 's1', 'path': 'Clienti/Fatture'},
      <String, dynamic>{'share_id': 's2', 'path': 'Progetti'},
    ]);
  });

  test('tagColor maps known names and falls back to gray', () {
    expect(tagColor('green'), const Color(0xFF4AC26B));
    expect(tagColor('unknown-name'), tagColor('gray'));
  });
}
