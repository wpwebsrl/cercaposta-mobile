import 'dart:io';
import 'dart:typed_data';

import 'package:cercaposta/core/api/api_providers.dart';
import 'package:cercaposta/core/api/services/followup_api.dart';
import 'package:cercaposta/core/api/services/message_api.dart';
import 'package:cercaposta/core/auth/auth_controller.dart';
import 'package:cercaposta/core/auth/secure_store.dart';
import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/core/providers.dart';
import 'package:cercaposta/core/theme/app_theme.dart';
import 'package:cercaposta/features/chat/chat_controller.dart';
import 'package:cercaposta/features/chat/chat_screen.dart';
import 'package:cercaposta/features/email/email_screen.dart';
import 'package:cercaposta/features/followups/followups_screen.dart';
import 'package:cercaposta/features/login/login_screen.dart';
import 'package:cercaposta/features/search/search_controller.dart';
import 'package:cercaposta/features/search/search_screen.dart';
import 'package:cercaposta/shared/models/auth.dart';
import 'package:cercaposta/shared/models/chat.dart';
import 'package:cercaposta/shared/models/followup.dart';
import 'package:cercaposta/shared/models/message.dart';
import 'package:cercaposta/shared/models/search.dart';
import 'package:cercaposta/shared/models/user.dart';
import 'package:cercaposta/shared/tag_colors.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deterministic App Store captures, invoked only by the asset workflow.
///
/// These tests render the real production screens with in-memory APIs and
/// notifiers. No screenshot job talks to a CercaPosta server, reads a mailbox,
/// or needs a user credential. The outer transform rasterizes the logical UI at
/// 2x so the compositor can resize it without softening the text.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadPreviewFont);

  for (final locale in const <String>['it', 'en']) {
    for (final device in _PreviewDevice.values) {
      testWidgets('$locale ${device.name} 01 search', (tester) async {
        final copy = _Copy(locale);
        await _capture(
          tester,
          locale: locale,
          device: device,
          name: '01_search',
          overrides: <Override>[
            searchProvider.overrideWith(
              () => _PreviewSearchController(_searchState(copy)),
            ),
          ],
          child: const SearchScreen(),
          afterPump: () async {
            await tester.enterText(find.byType(TextField).first, copy.query);
            await tester.pump();
          },
        );
      });

      testWidgets('$locale ${device.name} 02 chat', (tester) async {
        final copy = _Copy(locale);
        await _capture(
          tester,
          locale: locale,
          device: device,
          name: '02_chat',
          overrides: <Override>[
            chatProvider.overrideWith(
              () => _PreviewChatController(_chatState(copy)),
            ),
          ],
          child: const ChatScreen(),
        );
      });

      testWidgets('$locale ${device.name} 03 email', (tester) async {
        final copy = _Copy(locale);
        await _capture(
          tester,
          locale: locale,
          device: device,
          name: '03_email',
          overrides: <Override>[
            messageApiProvider.overrideWithValue(
              _PreviewMessageApi(_message(copy)),
            ),
          ],
          child: const EmailScreen(messageId: 'demo-message'),
        );
      });

      testWidgets('$locale ${device.name} 04 followups', (tester) async {
        final copy = _Copy(locale);
        await _capture(
          tester,
          locale: locale,
          device: device,
          name: '04_followups',
          overrides: <Override>[
            followupApiProvider.overrideWithValue(
              _PreviewFollowupApi(_followups(copy)),
            ),
          ],
          child: const FollowupsScreen(),
        );
      });

      testWidgets('$locale ${device.name} 05 secure login', (tester) async {
        await _capture(
          tester,
          locale: locale,
          device: device,
          name: '05_security',
          loggedIn: false,
          child: const LoginScreen(),
          settle: false,
          afterPump: () async {
            // Complete the one-shot logo animation at a deterministic frame.
            await tester.pump(const Duration(seconds: 6));
            await tester.pumpAndSettle();
          },
        );
      });
    }
  }
}

const _previewFontFamily = 'StorePreview';

Future<void> _loadPreviewFont() async {
  const candidates = <String>[
    '/System/Library/Fonts/Supplemental/Arial.ttf',
    '/System/Library/Fonts/SFNS.ttf',
    r'C:\Windows\Fonts\segoeui.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  ];
  final path = candidates
      .where((candidate) => File(candidate).existsSync())
      .firstOrNull;
  if (path == null) {
    throw StateError('No suitable preview font is installed on this runner');
  }
  final bytes = await File(path).readAsBytes();
  await (FontLoader(_previewFontFamily)
        ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes))))
      .load();
}

ThemeData _previewTheme() {
  final base = AppTheme.light();
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: _previewFontFamily),
    primaryTextTheme: base.primaryTextTheme.apply(
      fontFamily: _previewFontFamily,
    ),
  );
}

enum _PreviewDevice {
  iphone(logicalSize: Size(430, 932), scale: 2),
  ipad(logicalSize: Size(1032, 1376), scale: 2);

  const _PreviewDevice({required this.logicalSize, required this.scale});

  final Size logicalSize;
  final double scale;

  Size get rasterSize => logicalSize * scale;
}

Future<void> _capture(
  WidgetTester tester, {
  required String locale,
  required _PreviewDevice device,
  required String name,
  required Widget child,
  List<Override> overrides = const <Override>[],
  bool loggedIn = true,
  bool settle = true,
  Future<void> Function()? afterPump,
}) async {
  final raster = device.rasterSize;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = raster;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  const captureKey = ValueKey<String>('store-capture');
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: captureKey,
        child: ColoredBox(
          color: Colors.white,
          child: Align(
            alignment: Alignment.topLeft,
            child: Transform.scale(
              alignment: Alignment.topLeft,
              scale: device.scale,
              child: SizedBox.fromSize(
                size: device.logicalSize,
                child: ProviderScope(
                  overrides: <Override>[
                    activeServerProvider.overrideWith(_PreviewActiveServer.new),
                    authProvider.overrideWith(
                      () => _PreviewAuthController(
                        locale: locale,
                        loggedIn: loggedIn,
                      ),
                    ),
                    tagColorsProvider.overrideWith(
                      (ref) async => const <String, TagInfo>{
                        'contratti': (name: 'Contratti', color: 'green'),
                        'contracts': (name: 'Contracts', color: 'green'),
                        'importante': (name: 'Importante', color: 'orange'),
                        'important': (name: 'Important', color: 'orange'),
                      },
                    ),
                    ...overrides,
                  ],
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    locale: Locale(locale),
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    theme: _previewTheme(),
                    builder: (context, app) => MediaQuery(
                      data: MediaQueryData(
                        size: device.logicalSize,
                        devicePixelRatio: device.scale,
                        padding: const EdgeInsets.only(top: 22),
                        viewPadding: const EdgeInsets.only(top: 22),
                      ),
                      child: app!,
                    ),
                    home: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  if (settle) await tester.pumpAndSettle();
  if (afterPump != null) await afterPump();
  await expectLater(
    find.byKey(captureKey),
    matchesGoldenFile(
      '../../store_assets/raw/$locale/${device.name}/$name.png',
    ),
  );
}

class _PreviewActiveServer extends ActiveServer {
  @override
  String? build() => 'https://app.cercaposta.it';
}

class _PreviewAuthController extends AuthController {
  _PreviewAuthController({required this.locale, required this.loggedIn});

  final String locale;
  final bool loggedIn;

  @override
  AuthState build() => AuthState(
    status: loggedIn ? AuthStatus.loggedIn : AuthStatus.loggedOut,
    accessToken: loggedIn ? 'store-preview' : null,
    user: loggedIn
        ? UserInfo(
            id: 'store-user',
            username: 'demo@cercaposta.it',
            displayName: locale == 'it' ? 'Giulia Demo' : 'Julia Demo',
            role: 'user',
            language: locale,
            locale: locale == 'it' ? 'it-IT' : 'en-US',
            mustChangePassword: false,
          )
        : null,
    encStatus: 'active',
    dekAvailable: true,
  );

  @override
  Future<LoginResult?> resumeGoogleLogin() async => null;

  @override
  Future<LoginResult?> resumeAppleLogin() async => null;

  @override
  Future<SavedCredentials?> savedCredentials() async => null;
}

class _PreviewSearchController extends SearchController {
  _PreviewSearchController(this.preview);

  final SearchState preview;

  @override
  SearchState build() => preview;

  @override
  Future<void> search(String raw, {String sort = 'relevance'}) async {}

  @override
  Future<void> loadMore() async {}
}

class _PreviewChatController extends ChatController {
  _PreviewChatController(this.preview);

  final ChatState preview;

  @override
  ChatState build() => preview;

  @override
  Future<void> checkStatus() async {}
}

class _PreviewMessageApi extends MessageApi {
  _PreviewMessageApi(this.preview) : super(Dio());

  final MessageDetail preview;

  @override
  Future<MessageDetail> get(String id, {bool allowRemote = false}) async =>
      preview;

  @override
  Future<List<ThreadEntry>> thread(String id) async => const <ThreadEntry>[];
}

class _PreviewFollowupApi extends FollowupApi {
  _PreviewFollowupApi(this.preview) : super(Dio());

  final FollowupList preview;

  @override
  Future<FollowupList> list({int limit = 200, int offset = 0}) async =>
      offset == 0
      ? preview
      : const FollowupList(total: 0, items: <FollowupItem>[]);

  @override
  Future<FollowupStatus> status() async =>
      const FollowupStatus(configured: true, enabled: true, paused: null);
}

SearchState _searchState(_Copy c) => SearchState(
  hasSearched: true,
  total: 148,
  finished: true,
  hits: List<SearchHit>.generate(10, (index) {
    final data = c.searchRows[index % c.searchRows.length];
    return SearchHit(
      id: 'search-$index',
      subject: data.$1,
      fromName: data.$2,
      fromAddress: 'demo${index + 1}@example.com',
      date: DateTime.utc(2026, 8, 16 - index, 9 + index, 20),
      snippet: data.$3,
      hasAttachments: index != 2,
      attachmentCount: index.isEven ? 2 : 1,
      sizeBytes: 180000 + index * 42000,
      folders: const <String>['Posta in arrivo'],
      tags: <String>[index.isEven ? c.contractTag : c.importantTag],
      sort: <dynamic>[index],
    );
  }),
);

ChatState _chatState(_Copy c) => ChatState(
  available: true,
  aiEnabled: true,
  messages: <ChatMessage>[
    ChatMessage(role: 'user', content: c.chatQuestion),
    ChatMessage(
      role: 'assistant',
      content: c.chatAnswer,
      paging: const PagingNote(read: 12, total: 12),
      citations: <Citation>[
        Citation(
          n: 1,
          id: 'citation-1',
          subject: c.citationOne,
          fromName: c.citationSenderOne,
          fromAddress: 'elena@example.com',
          date: DateTime.utc(2026, 8, 12),
          snippet: c.citationSnippetOne,
          folder: 'Inbox',
        ),
        Citation(
          n: 2,
          id: 'citation-2',
          subject: c.citationTwo,
          fromName: c.citationSenderTwo,
          fromAddress: 'contracts@example.com',
          date: DateTime.utc(2026, 8, 9),
          snippet: c.citationSnippetTwo,
          folder: 'Inbox',
        ),
        Citation(
          n: 3,
          id: 'citation-3',
          subject: c.citationThree,
          fromName: c.citationSenderThree,
          fromAddress: 'admin@example.com',
          date: DateTime.utc(2026, 8, 7),
          snippet: c.citationSnippetThree,
          folder: 'Archive',
        ),
      ],
    ),
  ],
);

MessageDetail _message(_Copy c) => MessageDetail(
  id: 'demo-message',
  subject: c.emailSubject,
  fromName: c.emailSender,
  fromAddress: 'elena.bianchi@example.com',
  to: <Recipient>[
    Recipient(name: c.emailRecipient, address: 'giulia@example.com'),
  ],
  cc: const <Recipient>[],
  bcc: const <Recipient>[],
  dateSent: DateTime.utc(2026, 8, 16, 9, 30),
  threadId: 'demo-thread',
  bodyHtml: null,
  bodyText: c.emailBody,
  hasRemoteImages: false,
  rawMissing: false,
  isPec: false,
  pec: null,
  attachments: <AttachmentInfo>[
    const AttachmentInfo(
      id: 'attachment-1',
      filename: 'CercaPosta-proposal.pdf',
      contentType: 'application/pdf',
      extension: 'pdf',
      sizeBytes: 1284000,
      isInline: false,
    ),
    AttachmentInfo(
      id: 'attachment-2',
      filename: c.attachmentName,
      contentType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      extension: 'xlsx',
      sizeBytes: 684000,
      isInline: false,
    ),
  ],
  folders: <String>[c.inbox],
  tags: <TagRef>[
    TagRef(id: 'tag-1', name: c.contractTag, color: 'green'),
    TagRef(id: 'tag-2', name: c.importantTag, color: 'orange'),
  ],
);

FollowupList _followups(_Copy c) {
  final rows = <(String, String, String)>[
    (c.followupNameOne, c.followupAddressOne, c.followupSummaryOne),
    (c.followupNameTwo, c.followupAddressTwo, c.followupSummaryTwo),
    (c.followupNameThree, c.followupAddressThree, c.followupSummaryThree),
    (c.followupNameFour, c.followupAddressFour, c.followupSummaryFour),
    (c.followupNameFive, c.followupAddressFive, c.followupSummaryFive),
  ];
  final items = <FollowupItem>[
    for (var i = 0; i < rows.length; i++)
      FollowupItem.fromJson(<String, dynamic>{
        'id': 'followup-$i',
        'direction': 'their_turn',
        'state': i < 2 ? 'reminded' : 'open',
        'counterpart_name': rows[i].$1,
        'counterpart_address': rows[i].$2,
        'summary': rows[i].$3,
        'due_at': i < 2 ? '2026-08-${18 + i}T10:00:00Z' : null,
        'message_id': 'message-$i',
        'thread_id': 'thread-$i',
        'last_reminder_at': i < 2 ? '2026-08-16T10:00:00Z' : null,
        'reminder_count': i == 0 ? 2 : (i == 1 ? 1 : 0),
      }),
    FollowupItem.fromJson(<String, dynamic>{
      'id': 'my-turn-1',
      'direction': 'my_turn',
      'state': 'open',
      'counterpart_name': c.myTurnName,
      'counterpart_address': 'team@example.com',
      'summary': c.myTurnSummary,
      'message_id': 'message-my-turn',
      'thread_id': 'thread-my-turn',
    }),
  ];
  return FollowupList(
    total: items.length,
    items: items,
    counts: const FollowupCounts(theirTurn: 5, myTurn: 1),
  );
}

class _Copy {
  const _Copy(this.locale);

  final String locale;
  bool get it => locale == 'it';

  String get query =>
      it ? 'contratto energia rinnovabile' : 'renewable energy contract';
  String get contractTag => it ? 'Contratti' : 'Contracts';
  String get importantTag => it ? 'Importante' : 'Important';
  String get inbox => it ? 'Posta in arrivo' : 'Inbox';

  List<(String, String, String)> get searchRows => it
      ? const <(String, String, String)>[
          (
            'Rinnovo contratto energia 2027',
            'Elena Bianchi',
            'In allegato trovi la proposta aggiornata e le nuove condizioni...',
          ),
          (
            'Proposta economica e tempi di attivazione',
            'Energia Verde Italia',
            'Abbiamo confermato il prezzo e la decorrenza dal 1° gennaio...',
          ),
          (
            'Verbale della riunione di martedì',
            'Marco Conti',
            'Riepilogo delle decisioni sul rinnovo e dei prossimi passaggi...',
          ),
          (
            'Documentazione firmata',
            'Ufficio Contratti',
            'La documentazione è completa. Rimane da confermare il referente...',
          ),
          (
            'Conferma condizioni di fornitura',
            'Sara Romano',
            'Confermiamo le condizioni discusse e la durata di ventiquattro mesi...',
          ),
        ]
      : const <(String, String, String)>[
          (
            'Renewable energy contract renewal',
            'Elena Bianchi',
            'The updated proposal and the new terms are attached...',
          ),
          (
            'Commercial proposal and activation schedule',
            'Green Energy Europe',
            'We confirmed the price and the January 1 activation date...',
          ),
          (
            'Minutes from Tuesday’s meeting',
            'Mark Cooper',
            'A summary of the renewal decisions and the next steps...',
          ),
          (
            'Signed documents',
            'Contracts Team',
            'The documentation is complete. We only need to confirm the contact...',
          ),
          (
            'Supply terms confirmed',
            'Sarah Miller',
            'We confirm the agreed terms and the twenty-four-month duration...',
          ),
        ];

  String get chatQuestion => it
      ? 'Quali sono le condizioni concordate per il rinnovo del contratto energia?'
      : 'What terms did we agree on for the energy contract renewal?';
  String get chatAnswer => it
      ? 'Il rinnovo decorre dal 1° gennaio 2027, dura 24 mesi e mantiene il prezzo concordato nella proposta del 12 agosto. La firma deve essere completata entro il 30 settembre [1][2]. Il referente operativo indicato è Elena Bianchi [3].'
      : 'The renewal starts on January 1, 2027, runs for 24 months, and keeps the price agreed in the August 12 proposal. Signature is due by September 30 [1][2]. Elena Bianchi is the designated operational contact [3].';
  String get citationOne =>
      it ? 'Rinnovo contratto energia 2027' : 'Energy contract renewal 2027';
  String get citationTwo =>
      it ? 'Proposta economica approvata' : 'Commercial proposal approved';
  String get citationThree =>
      it ? 'Referente operativo del contratto' : 'Contract operational contact';
  String get citationSenderOne => 'Elena Bianchi';
  String get citationSenderTwo => it ? 'Ufficio Contratti' : 'Contracts Team';
  String get citationSenderThree => it ? 'Amministrazione' : 'Administration';
  String get citationSnippetOne => it
      ? 'Decorrenza dal 1° gennaio e durata di 24 mesi.'
      : 'Starting January 1 with a term of 24 months.';
  String get citationSnippetTwo => it
      ? 'Firma richiesta entro il 30 settembre.'
      : 'Signature requested by September 30.';
  String get citationSnippetThree => it
      ? 'Elena Bianchi sarà il referente operativo.'
      : 'Elena Bianchi will be the operational contact.';

  String get emailSubject =>
      it ? 'Proposta definitiva per il rinnovo' : 'Final renewal proposal';
  String get emailSender => 'Elena Bianchi';
  String get emailRecipient => it ? 'Giulia Demo' : 'Julia Demo';
  String get attachmentName => it ? 'Condizioni-2027.xlsx' : 'Terms-2027.xlsx';
  String get emailBody => it
      ? '''Buongiorno Giulia,

come concordato, trovi in allegato la proposta definitiva per il rinnovo del contratto.

La fornitura decorrerà dal 1° gennaio 2027 per 24 mesi. Abbiamo mantenuto le condizioni economiche discusse durante l’ultima riunione.

Per completare la pratica è sufficiente restituire il documento firmato entro il 30 settembre.

Rimango a disposizione per qualsiasi chiarimento.

Un cordiale saluto,
Elena'''
      : '''Hello Julia,

As agreed, the final proposal for the contract renewal is attached.

The supply will start on January 1, 2027 and run for 24 months. We kept the commercial terms discussed during our latest meeting.

To complete the process, please return the signed document by September 30.

Please let me know if you need any clarification.

Kind regards,
Elena''';

  String get followupNameOne => it ? 'Luca Ferri' : 'Luke Harris';
  String get followupAddressOne => 'luca.ferri@example.com';
  String get followupSummaryOne => it
      ? 'Conferma del preventivo per il progetto Aurora'
      : 'Confirmation of the Aurora project quote';
  String get followupNameTwo => it ? 'Studio Contabile' : 'Accounting Office';
  String get followupAddressTwo => 'accounting@example.com';
  String get followupSummaryTwo => it
      ? 'Documenti necessari per la chiusura mensile'
      : 'Documents needed for the monthly close';
  String get followupNameThree => it ? 'Marta Riva' : 'Martha Reed';
  String get followupAddressThree => 'marta.riva@example.com';
  String get followupSummaryThree => it
      ? 'Disponibilità per la riunione di avanzamento'
      : 'Availability for the project review meeting';
  String get followupNameFour => it ? 'Ufficio Acquisti' : 'Purchasing Team';
  String get followupAddressFour => 'purchasing@example.com';
  String get followupSummaryFour => it
      ? 'Approvazione dell’ordine e data di consegna'
      : 'Order approval and expected delivery date';
  String get followupNameFive => it ? 'Paolo Serra' : 'Paul Stone';
  String get followupAddressFive => 'paolo.serra@example.com';
  String get followupSummaryFive => it
      ? 'Conferma delle modifiche richieste al contratto'
      : 'Confirmation of the requested contract changes';
  String get myTurnName => it ? 'Team commerciale' : 'Sales Team';
  String get myTurnSummary => it
      ? 'Rispondere alla richiesta di aggiornamento'
      : 'Reply to the status update request';
}
