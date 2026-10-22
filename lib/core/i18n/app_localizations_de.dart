// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get personalAiLabel => 'Persönliche KI';

  @override
  String get managedAiLabel => 'CercaPosta KI';

  @override
  String get errorPersonalAiUnavailable =>
      'Die persönliche KI ist pausiert: Prüfen Sie in den Webeinstellungen Ihren Tarif, Ihre Einwilligung und ob Ihr Archiv entsperrt ist.';

  @override
  String get errorSessionChanged =>
      'Die Sitzung hat sich geändert. Versuchen Sie es mit dem aktuell angemeldeten Konto erneut.';

  @override
  String get appName => 'CercaPosta';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionConfirm => 'Bestätigen';

  @override
  String get actionClose => 'Schließen';

  @override
  String get actionRetry => 'Erneut versuchen';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionApply => 'Anwenden';

  @override
  String get actionClear => 'Leeren';

  @override
  String get actionContinue => 'Weiter';

  @override
  String get actionRemove => 'Entfernen';

  @override
  String get actionOpenInBrowser => 'Im Browser öffnen';

  @override
  String get loading => 'Wird geladen…';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get serverTitle => 'Wählen Sie den Server';

  @override
  String get serverSubtitle =>
      'Geben Sie die Adresse Ihres CercaPosta-Servers ein.';

  @override
  String get serverUrlLabel => 'Serveradresse';

  @override
  String get serverUrlHint => 'https://mail.example.com';

  @override
  String get serverValidating => 'Server validieren...';

  @override
  String get serverInvalid => 'Ungültige Adresse oder Server nicht erreichbar';

  @override
  String get serverNotCercaPosta =>
      'Dieser Server ist keine CercaPosta-Instanz';

  @override
  String get serverSavedTitle => 'Gespeicherte Server';

  @override
  String get serverNeedsSetup =>
      'Dieser Server muss noch über die Weboberfläche eingerichtet werden.';

  @override
  String get serverUpdateRequired =>
      'Aktualisieren Sie die App, um diesen Server zu verwenden.';

  @override
  String get loginTitle => 'Anmelden';

  @override
  String get loginHeading => 'Bei CercaPosta anmelden';

  @override
  String get loginTagline => 'Ihr E-Mail-Archiv, überall durchsuchbar';

  @override
  String get loginUsername => 'Benutzername';

  @override
  String get loginPassword => 'Passwort';

  @override
  String get loginButton => 'Anmelden';

  @override
  String get loginPasskey => 'Mit einem Passkey anmelden';

  @override
  String get loginGoogle => 'Mit Google anmelden';

  @override
  String get loginApple => 'Mit Apple anmelden';

  @override
  String get loginChangeServer => 'Server ändern';

  @override
  String get loginBiometric => 'Mit Biometrie anmelden';

  @override
  String get loginBiometricReason => 'Zugriff auf Ihr E-Mail-Archiv';

  @override
  String get loginEnableBiometricTitle => 'Schnelle Anmeldung';

  @override
  String get loginEnableBiometricBody =>
      'Möchten Sie beim nächsten Mal Face ID oder Ihren Fingerabdruck verwenden? Dieses Gerät speichert eine widerrufbare, biometrisch geschützte Autorisierung. Die App speichert Ihr Kontopasswort nicht.';

  @override
  String sharedFromLabel(String name) {
    return 'von $name';
  }

  @override
  String sharedReaderBanner(String name) {
    return 'Von $name freigegebener Ordner – schreibgeschützt';
  }

  @override
  String get totpTitle => 'Zweistufige Überprüfung';

  @override
  String get totpSubtitle =>
      'Geben Sie den Code aus Ihrer Authenticator-App ein.';

  @override
  String get totpCode => '6-stelliger Code';

  @override
  String get totpButton => 'Prüfen';

  @override
  String get unlockTitle => 'Archiv entsperren';

  @override
  String get unlockDescription =>
      'Ihr Archiv ist verschlüsselt. Geben Sie Ihr Passwort ein, um auf den Inhalt zuzugreifen.';

  @override
  String get unlockPassword => 'Passwort';

  @override
  String get unlockButton => 'Entsperren';

  @override
  String get unlockBiometric => 'Biometrisch entsperren';

  @override
  String get unlockEnableBiometricTitle => 'Schnelles Entsperren';

  @override
  String get unlockEnableBiometricBody =>
      'Möchten Sie Face ID oder Ihren Fingerabdruck zum Entsperren des Archivs verwenden? Dieses Gerät speichert eine widerrufbare, biometrisch geschützte Autorisierung.';

  @override
  String get unlockEnableBiometricYes => 'Ja, aktivieren';

  @override
  String get unlockEnableBiometricNo => 'Nein, danke';

  @override
  String get unlockReason => 'Entsperren Sie Ihr verschlüsseltes Archiv';

  @override
  String get firstPasswordTitle => 'Setzen Sie ein neues Passwort';

  @override
  String get firstPasswordSubtitle =>
      'Beim ersten Zugriff müssen Sie ein persönliches Passwort auswählen (der Administrator wird es nie erfahren).';

  @override
  String get firstPasswordNew => 'Neues Passwort';

  @override
  String get firstPasswordConfirm => 'Passwort bestätigen';

  @override
  String get firstPasswordMismatch => 'Die Passwörter stimmen nicht überein';

  @override
  String get kitTitle => 'Wiederherstellungskit';

  @override
  String get kitBody =>
      'Bewahren Sie diesen Code sicher auf: Damit können Sie Ihr Archiv wiederherstellen, falls Sie Ihr Passwort vergessen. Er wird NUR jetzt angezeigt.';

  @override
  String get kitCopy => 'Kopieren';

  @override
  String get kitCopied => 'In die Zwischenablage kopiert';

  @override
  String get recoveryTitle => 'Archiv-Wiederherstellung';

  @override
  String get recoverySubtitle =>
      'Ihr Passwort wurde vom Administrator zurückgesetzt. Geben Sie den Code Ihres Wiederherstellungskits ein und wählen Sie ein neues Passwort.';

  @override
  String get recoverySecretLabel => 'Wiederherstellungscode';

  @override
  String get navSearch => 'Suchen';

  @override
  String get navChat => 'KI-Chat';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get navNotifications => 'Warnungen';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsEmpty => 'Keine Meldungen.';

  @override
  String get notificationsDismiss => 'Ausblenden';

  @override
  String get notificationsDismissAll => 'Alle löschen';

  @override
  String get notificationsDismissAllConfirm =>
      'Alle Benachrichtigungen löschen? Dies kann nicht rückgängig gemacht werden.';

  @override
  String get notifReprocessTitle =>
      'Archiv erneut verarbeiten, um aktuelle Verbesserungen anzuwenden';

  @override
  String get notifReprocessBody =>
      'Ein App-Update verbessert die Verarbeitung bereits archivierter E-Mails. Beispielsweise zählen in Signaturen eingebettete Bilder nicht mehr als Anhänge. Die erneute Verarbeitung des Archivs starten Sie in der Web-App.';

  @override
  String get searchHint => 'Suchen… (from:, tag:, has:pdf…)';

  @override
  String get searchVoice => 'Sprachsuche';

  @override
  String get searchVoiceListening => 'Spracherkennung läuft…';

  @override
  String get searchVoiceUnavailable => 'Spracherkennung nicht verfügbar';

  @override
  String get searchVoicePermission => 'Mikrofonzugriff verweigert';

  @override
  String get searchFilters => 'Filter';

  @override
  String get searchNoResults => 'Keine Ergebnisse';

  @override
  String get searchNewResults => 'Neue Ergebnisse';

  @override
  String get sortTooltip => 'Ergebnisse sortieren';

  @override
  String get sortRelevance => 'Relevanz';

  @override
  String get sortNewest => 'Neueste';

  @override
  String get sortOldest => 'Älteste zuerst';

  @override
  String get searchLoading => 'Durchsuchen...';

  @override
  String get searchEmptyPrompt =>
      'Durchsuchen Sie Ihr Archiv mit Stichwörtern oder Suchoperatoren.';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ergebnisse',
      one: '1 Ergebnis',
      zero: 'Keine Ergebnisse',
    );
    return '$_temp0';
  }

  @override
  String attachmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anhänge',
      one: '1 Anhang',
    );
    return '$_temp0';
  }

  @override
  String get filtersTitle => 'Filter';

  @override
  String get filterFrom => 'Von';

  @override
  String get filterTo => 'An / CC';

  @override
  String get filterSubject => 'Betreff';

  @override
  String get filterHasAttachments => 'Hat Anhänge';

  @override
  String get filterAttachmentExt => 'Dateityp des Anhangs (z. B. pdf)';

  @override
  String get filterDateFrom => 'Nach';

  @override
  String get filterDateTo => 'Vorher';

  @override
  String get filterTags => 'Tags';

  @override
  String get filterFolders => 'Ordner';

  @override
  String get foldersTitle => 'Ordner';

  @override
  String get foldersAll => 'Alle Ordner';

  @override
  String get foldersRefresh => 'Aktualisieren';

  @override
  String get foldersEmpty => 'Keine Ordner im Archiv';

  @override
  String get foldersExpand => 'Aufklappen';

  @override
  String get foldersCollapse => 'Zuklappen';

  @override
  String foldersMultiple(int count) {
    return '$count Ordner';
  }

  @override
  String get aboutTitle => 'Über CercaPosta';

  @override
  String get aboutCompany => 'WpWeb S.r.l.';

  @override
  String get aboutBuildLabel => 'Build';

  @override
  String get aboutWebsite => 'Besuchen Sie wpweb.com';

  @override
  String get aboutCredits =>
      'CercaPosta ist ein Produkt von WpWeb: ein intelligentes, verschlüsseltes und durchsuchbares E-Mail-Archiv.\nAlle Ihre E-Mails, endlich an einem Ort.\nJahrelange Nachrichten, Unterhaltungen und Anhänge, gesammelt und geordnet.\nKeine verstreuten Postfächer, alten Backups oder vergessenen Dateien mehr.\nCercaPosta führt alles in einem sicheren Archiv zusammen, das stets griffbereit ist.\nEine E-Mail zu finden, ist keine Schatzsuche mehr.\nGeben Sie ein, woran Sie sich erinnern, so wie Sie es sagen würden.\nEin Name, ein Datum, ein Wort: Die Ergebnisse erscheinen im Handumdrehen.\nSie erinnern sich nicht an den genauen Wortlaut? Kein Problem.\nCercaPosta versteht den Sinn Ihrer Suche, nicht nur die Wörter.\nSuchen Sie nach dem „Angebot des Klempners vom letzten Jahr“?\nSie finden es, auch wenn in der E-Mail das Wort „Angebot“ gar nicht vorkam.\nEin intelligenter Assistent liest Ihre E-Mails für Sie.\nStellen Sie Fragen in Ihren eigenen Worten und erhalten Sie klare Antworten.\n„Wann habe ich den Zahnarzttermin bestätigt?“\n„Welche IBAN hat mir der Lieferant geschickt?“\nDer Assistent nennt die passenden E-Mails als Quellen, damit Sie die Angaben selbst überprüfen können.\nAuch Anhänge werden durchsuchbar.\nPDFs, Dokumente, Tabellen und sogar Text in Bildern.\nDiese Rechnung, dieser Vertrag, dieses Foto: nur eine Suche entfernt.\nSie müssen nicht mehr stundenlang Ihren Posteingang nach einem Detail durchsuchen.\nFiltern Sie nach Ordner, Tag, Absender oder Datum.\nGrenzen Sie Ihre Suche mit wenigen Klicks ein und kommen Sie direkt zum Ziel.\nJede Nachricht wird übersichtlich und gut lesbar geöffnet.\nUnd vor allem: Ihre Daten gehören Ihnen, und nur Ihnen.\nAlle gespeicherten Daten werden mit Ihrem persönlichen Schlüssel verschlüsselt.\nEine gestohlene Datenbank oder ein gestohlenes Backup bleibt unlesbar.\nDer Sicherheitsschlüssel gehört Ihnen allein.\nCercaPosta ist ein schreibgeschütztes Archiv.\nEs sendet und beantwortet keine Nachrichten und ändert nichts in Ihren ursprünglichen Postfächern.\nEs bewahrt und schützt, ohne die Quelle anzutasten.\nFür Menschen mit vielen E-Mails und wenig Zeit.\nFür Fachleute, Unternehmen, Kanzleien, Büros und Einrichtungen.\nFür alle einfach zu bedienen.\nOhne Handbuch und ohne Umstände.\nÖffnen Sie die App, geben Sie ein, was Sie suchen, und finden Sie es. Das ist alles.\nDas Gedächtnis Ihrer Korrespondenz, immer dabei.\nWas Sie brauchen, genau dann, wenn Sie es brauchen.\nFinden Sie in Sekunden wieder, was Sie für immer verloren glaubten.\nRufen Sie Informationen, Vereinbarungen und Entscheidungen aus Ihren E-Mails ab.\nMachen Sie aus jahrelanger Korrespondenz eine lebendige, durchsuchbare Informationsquelle.\nMehr Ordnung, weniger Stress.\nMehr Zeit für das, was wirklich zählt.\nSchnell beim Suchen, diskret beim Aufbewahren.\nZuverlässig, wann immer Sie es brauchen.\nVon Grund auf sicher, bewusst einfach.\nIhr E-Mail-Archiv, intelligent und geschützt.\nAlles durchsuchbar, von Anfang an übersichtlich.\nCercaPosta: Alles finden, nichts verlieren.\nEin Produkt von WpWeb.\nTechnologie, die das digitale Leben vereinfacht.\nVielen Dank, dass Sie sich für CercaPosta entschieden haben.';

  @override
  String get emailLoading => 'Nachricht wird geladen…';

  @override
  String get emailNoBody => 'Kein Inhalt zum Anzeigen.';

  @override
  String get emailRawMissing =>
      'Die ursprüngliche Nachricht ist nicht mehr verfügbar: Es werden nur Metadaten angezeigt.';

  @override
  String get emailAttachments => 'Anhänge';

  @override
  String get emailThread => 'Gespräch';

  @override
  String get emailOpenAttachment => 'Anhang öffnen';

  @override
  String get emailShowRemoteImages => 'Remote-Bilder anzeigen';

  @override
  String get emailAlwaysShowRemoteImagesFromSender =>
      'Bilder dieses Absenders immer anzeigen';

  @override
  String get emailPecBadge => 'PEC';

  @override
  String get emailTo => 'An';

  @override
  String get emailCc => 'CC';

  @override
  String get emailDate => 'Datum';

  @override
  String get emailFrom => 'Von';

  @override
  String get emailDetails => 'Details';

  @override
  String get emailThreadEmpty =>
      'Keine anderen Nachrichten in diesem Gespräch.';

  @override
  String get attachmentLoading => 'Ladevorschau...';

  @override
  String get attachmentUnsupported =>
      'Vorschau nicht verfügbar für diesen Dateityp.';

  @override
  String get chatTitle => 'KI-Chat';

  @override
  String get chatHint => 'Stellen Sie eine Frage zu Ihrem Archiv...';

  @override
  String get chatSend => 'Senden';

  @override
  String get chatNotConfigured =>
      'Der KI-Chat ist auf diesem Server nicht konfiguriert.';

  @override
  String get chatDisabled => 'Der KI-Chat ist auf diesem Server deaktiviert.';

  @override
  String get chatNew => 'Neues Gespräch';

  @override
  String get chatHistory => 'Verlauf';

  @override
  String get chatHistoryEmpty => 'Keine gespeicherten Gespräche.';

  @override
  String get chatCitations => 'Quellen';

  @override
  String get chatPhaseUnderstanding => 'Verstehen...';

  @override
  String get chatPhaseSearching => 'Durchsuchen...';

  @override
  String get chatPhaseEmbedding => 'Semantische Analyse...';

  @override
  String get chatPhaseReranking => 'Rangfolge...';

  @override
  String get chatPhaseGenerating => 'Antwort generieren...';

  @override
  String chatActivitySearch(String q) {
    return 'Suche nach „$q“';
  }

  @override
  String chatActivityThread(String s) {
    return 'Unterhaltung „$s“ wird gelesen';
  }

  @override
  String get chatActivityThreadGeneric => 'Ein Gespräch lesen';

  @override
  String get chatActivityFollowups => 'Prüfung der Antworterwartungen';

  @override
  String get chatActivityStats => 'Archivstatistiken werden berechnet';

  @override
  String chatActivityContact(String a) {
    return 'Verlauf für $a wird zusammengestellt';
  }

  @override
  String chatActivityAttachments(String q) {
    return 'Anhänge zu „$q“ werden gelesen';
  }

  @override
  String get chatActivityAttachmentsGeneric => 'Anhänge werden gelesen';

  @override
  String chatCitationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count E-Mails',
      one: '1 E-Mail',
    );
    return '$_temp0';
  }

  @override
  String chatCitationsOthers(int count) {
    return 'und $count weitere';
  }

  @override
  String chatCitationsShowAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Die übrigen $count anzeigen',
      one: 'Letzte E-Mail anzeigen',
    );
    return '$_temp0';
  }

  @override
  String get chatCitationsUnusedLegend =>
      'Ausgegraut: gelesene E-Mails, die nicht für die Antwort verwendet wurden.';

  @override
  String chatPagingRead(int read, int total) {
    return 'Für diese Suche wurden $read von $total E-Mails gelesen.';
  }

  @override
  String chatPagingAll(int total) {
    return 'Für diese Suche wurden alle $total E-Mails gelesen.';
  }

  @override
  String get chatEmbeddingFailed =>
      'Semantische Suche nicht verfügbar: Die Ergebnisse basieren nur auf Stichwörtern.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLegalAndSupport => 'Rechtliche Hinweise und Support';

  @override
  String get legalPrivacy => 'Datenschutzerklärung';

  @override
  String get legalTerms => 'Nutzungsbedingungen';

  @override
  String get legalSupport => 'Support';

  @override
  String get legalSupportHint =>
      'Kontakte, Telefonnummer und Möglichkeiten, Hilfe anzufordern';

  @override
  String get googleErrorCancelled => 'Google-Anmeldung wurde abgesagt';

  @override
  String get googleErrorState =>
      'Die Google-Sitzung ist nicht mehr gültig: Melden Sie sich erneut an';

  @override
  String get googleErrorConfiguration =>
      'Google-Anmeldung ist auf dem Server nicht korrekt konfiguriert';

  @override
  String get googleErrorIdentity =>
      'Google konnte Ihre Identität nicht überprüfen';

  @override
  String get googleErrorLinkRequired =>
      'Diese Adresse ist bereits registriert: Verknüpfen Sie Google zunächst in Ihrem Webprofil, bevor Sie es hier verwenden.';

  @override
  String get googleErrorRegistrationRequired =>
      'Erstellen Sie zuerst das Konto auf der Website und melden Sie sich dann von dieser App an';

  @override
  String get googleErrorInactive => 'Das CercaPosta-Konto ist nicht aktiv';

  @override
  String get googleErrorInvalid =>
      'Google-Anmeldung ist ungültig oder abgelaufen: Versuchen Sie es erneut';

  @override
  String get googleErrorDisabled =>
      'Google-Anmeldung ist auf diesem Server nicht aktiviert';

  @override
  String get googleErrorUnavailable => 'Google-Anmeldung ist nicht verfügbar';

  @override
  String get appleErrorCancelled => 'Apple-Anmeldung wurde abgesagt';

  @override
  String get appleErrorState =>
      'Die Apple-Sitzung ist nicht mehr gültig: Melden Sie sich erneut an';

  @override
  String get appleErrorIdentity =>
      'Apple konnte Ihre Identität nicht überprüfen';

  @override
  String get appleErrorLinkRequired =>
      'Diese Adresse ist bereits registriert: Verknüpfen Sie Apple zunächst in Ihrem Webprofil, bevor Sie es hier verwenden.';

  @override
  String get appleErrorRegistrationRequired =>
      'Erstellen Sie zuerst das Konto auf der Website und melden Sie sich dann von dieser App an';

  @override
  String get appleErrorInactive => 'Das CercaPosta-Konto ist nicht aktiv';

  @override
  String get appleErrorInvalid =>
      'Apple-Anmeldung ist ungültig oder abgelaufen: Versuchen Sie es erneut';

  @override
  String get appleErrorDisabled =>
      'Apple-Anmeldung ist auf diesem Server nicht aktiviert';

  @override
  String get appleErrorUnavailable => 'Apple-Anmeldung ist nicht verfügbar';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageIt => 'Italienisch';

  @override
  String get settingsLanguageEn => 'Englisch';

  @override
  String get settingsTheme => 'Erscheinungsbild';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsThemeAuto => 'Automatisch';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsRemoteImages => 'Bilder in E-Mail';

  @override
  String get settingsRemoteImagesAlways => 'Immer Remote-Bilder anzeigen';

  @override
  String get settingsRemoteImagesWarning =>
      'Bequemer, kann Absendern jedoch verraten, dass Sie eine E-Mail geöffnet haben. Erlauben Sie zum Schutz Ihrer Privatsphäre nur vertrauenswürdige Absender.';

  @override
  String get settingsOsNotifications => 'Systemmeldungen';

  @override
  String get settingsOsNotificationsHint =>
      'Zeigt neue Benachrichtigungen in der Mitteilungszentrale des Telefons an. Unter Android erfolgt die Prüfung etwa alle 15 Minuten, unter iOS, sobald das System dies erlaubt.';

  @override
  String get settingsOsNotificationsDenied =>
      'Berechtigung verweigert: Aktivieren Sie CercaPosta-Benachrichtigungen in den Systemeinstellungen.';

  @override
  String get settingsBiometric => 'Biometrisches Anmelden und Entsperren';

  @override
  String get settingsBiometricEnablePrompt =>
      'Bestätigen Sie Ihr Passwort, um dieses Gerät zu autorisieren, und vervollständigen Sie dann die biometrische Verifizierung. Die App behält Ihr Passwort nicht.';

  @override
  String get settingsSessions => 'Geräte & Sessions';

  @override
  String get passkeysTitle => 'Passkeys';

  @override
  String get passkeysSettingsHint =>
      'Melden Sie sich an, ohne Ihr Passwort einzugeben';

  @override
  String get passkeysDescription =>
      'Passkeys nutzen die sichere Entsperrung Ihres Geräts, etwa Fingerabdruck, Gesichtserkennung oder PIN. Der private Schlüssel verlässt niemals das Gerät oder Ihren Passkey-Anbieter.';

  @override
  String get passkeysAdd => 'Passkey hinzufügen';

  @override
  String get passkeysEmpty => 'Sie haben noch keine Passkeys registriert.';

  @override
  String get passkeysSynced => 'Synchronisiert';

  @override
  String get passkeysDeviceBound => 'Nur dieses Gerät';

  @override
  String passkeysCreated(String date) {
    return 'Erstellt am $date';
  }

  @override
  String passkeysLastUsed(String date) {
    return 'Zuletzt verwendet: $date';
  }

  @override
  String get passkeysRename => 'Umbenennen';

  @override
  String get passkeysRenameTitle => 'Passkey umbenennen';

  @override
  String get passkeysName => 'Passkey-Name';

  @override
  String get passkeysRemoveTitle => 'Passkey entfernen';

  @override
  String passkeysRemoveConfirm(String name) {
    return 'Passkey „$name“ entfernen? Sie können ihn danach nicht mehr zur Anmeldung verwenden.';
  }

  @override
  String get passkeysPasswordStays =>
      'Passkeys sind optional: Passwort und Google-Anmeldung bleiben verfügbar. Bei einem verschlüsselten Archiv benötigt ein neues oder nicht vertrauenswürdiges Gerät weiterhin das Passwort oder das Wiederherstellungskit zum Entsperren der Inhalte.';

  @override
  String get passkeyErrorCancelled => 'Vorgang abgebrochen';

  @override
  String get passkeyErrorNoCredential =>
      'Auf diesem Gerät ist kein CercaPosta-Passkey verfügbar';

  @override
  String get passkeyErrorDomainNotAssociated =>
      'Dieser Server ist noch nicht korrekt mit der App für Passkeys verknüpft';

  @override
  String get passkeyErrorUnavailable =>
      'Passkeys sind auf diesem Gerät nicht verfügbar. Sie können sich weiterhin mit Ihrem Passwort anmelden.';

  @override
  String get passkeyErrorTimeout =>
      'Die Zeit für die Passkey-Anfrage ist abgelaufen. Versuchen Sie es erneut.';

  @override
  String get passkeyErrorInvalid =>
      'Der Passkey wurde nicht erkannt oder ist nicht mehr gültig';

  @override
  String get passkeyErrorNotConfigured =>
      'Passkeys sind auf diesem Server noch nicht konfiguriert';

  @override
  String get passkeyErrorAlreadyRegistered =>
      'Dieser Passkey ist bereits registriert';

  @override
  String get settingsLogout => 'Abmelden';

  @override
  String get settingsAbout => 'Über CercaPosta';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get sessionsTitle => 'Geräte & Sessions';

  @override
  String get sessionsCurrent => 'Dieses Gerät';

  @override
  String get sessionsRevoke => 'Trennen';

  @override
  String get sessionsRevokeAll => 'Alle Geräte trennen';

  @override
  String get sessionsRevokeAllConfirm =>
      'Trennen Sie alle Geräte? Sie müssen sich bei jedem erneut anmelden.';

  @override
  String get sessionsEmpty => 'Keine aktiven Sitzungen.';

  @override
  String sessionsLastSeen(String when) {
    return 'Zuletzt aktiv: $when';
  }

  @override
  String sessionsCreated(String when) {
    return 'Aktiv seit: $when';
  }

  @override
  String sessionsIp(String ip) {
    return 'IP-Adresse: $ip';
  }

  @override
  String get serverHttpsRequired =>
      'Der Server muss HTTPS verwenden. Einfache http://-Adressen sind nicht zulässig.';

  @override
  String get serverRemoveSaved => 'Entfernen von gespeicherten Servern';

  @override
  String get searchClear => 'Suche löschen';

  @override
  String get searchLoadMoreError =>
      'Laden fehlgeschlagen. Tippen Sie, um es erneut zu versuchen.';

  @override
  String get filterSize => 'Größe';

  @override
  String get filterSizeGreater => 'größer als';

  @override
  String get filterSizeLess => 'weniger als';

  @override
  String get filterAccount => 'Konto (Quell-ID)';

  @override
  String get emailBcc => 'BCC';

  @override
  String get emailLinkError => 'Kann den Link nicht öffnen';

  @override
  String get attachmentShare => 'Teilen';

  @override
  String get attachmentShareError => 'Konnte den Anhang nicht teilen';

  @override
  String get chatStop => 'Stoppen';

  @override
  String get chatDelete => 'Gespräch löschen';

  @override
  String get chatDeleteConfirm => 'Löschen Sie dieses Gespräch?';

  @override
  String get chatRename => 'Umbenennen';

  @override
  String get chatRenameTitle => 'Unterhaltung umbenennen';

  @override
  String get chatStatusError => 'Chat-Status konnte nicht überprüft werden';

  @override
  String get settingsChangeServer => 'Server ändern';

  @override
  String get settingsChangeServerConfirm =>
      'Server wechseln? Sie werden vom aktuellen Server abgemeldet.';

  @override
  String errorWeakPasswordDetail(String requirements) {
    return 'Das Passwort muss enthalten: $requirements';
  }

  @override
  String get pwMinLength => 'eine größere Länge';

  @override
  String get pwRequireLower => 'einen Kleinbuchstaben';

  @override
  String get pwRequireUpper => 'einen Großbuchstaben';

  @override
  String get pwRequireDigit => 'eine Ziffer';

  @override
  String get pwRequireSymbol => 'ein Symbol';

  @override
  String get pwMinCharClasses => 'mehr Zeichentypen';

  @override
  String get updateAvailable => 'Eine neuere Version der App ist verfügbar.';

  @override
  String get updateRequiredTitle => 'Update erforderlich';

  @override
  String updateRequiredBody(String current) {
    return 'Diese App-Version ($current) wird vom Server nicht mehr unterstützt. Aktualisieren Sie auf die neueste Version, um CercaPosta weiterhin zu verwenden.';
  }

  @override
  String get updateRequiredButton => 'Jetzt aktualisieren';

  @override
  String get updateStoreError =>
      'Der Store konnte nicht geöffnet werden. Aktualisieren Sie die App manuell über den App Store oder Play Store.';

  @override
  String get emailPecSection => 'PEC-Transportumschlag';

  @override
  String get emailPecTransportFrom => 'Transportiert von';

  @override
  String get emailPecTransportSubject => 'Betreff des Transportumschlags';

  @override
  String get emailPecTransportDate => 'Beförderungsdatum';

  @override
  String get emailPecDaticert => 'Zertifizierung (daticert.xml) vorhanden';

  @override
  String get settingsStorage => 'Speicherplatz';

  @override
  String settingsStorageValue(String used, String quota, String percent) {
    return '$used von $quota ($percent %)';
  }

  @override
  String settingsStorageUnlimited(String used) {
    return '$used · unbegrenzt';
  }

  @override
  String get errorInvalidCredentials => 'Ungültige Zugangsdaten';

  @override
  String get errorAccountBanned =>
      'Konto vorübergehend gesperrt wegen zu vielen Versuchen';

  @override
  String get errorInvalidToken =>
      'Sitzung abgelaufen, bitte melden Sie sich erneut an';

  @override
  String get errorInvalidRefresh =>
      'Sitzung ungültig, bitte melden Sie sich erneut an';

  @override
  String get errorForbidden => 'Vorgang nicht zulässig';

  @override
  String get errorFeatureNotInPlan =>
      'Diese Funktion ist nicht im aktuellen Plan enthalten';

  @override
  String get errorAdminNotOnMobile =>
      'Admin-Funktionen sind auf Mobilgeräten nicht verfügbar';

  @override
  String get errorTotpInvalidCode => 'Ungültiger Code';

  @override
  String get errorTotpExpired =>
      'Code abgelaufen, bitte melden Sie sich erneut an';

  @override
  String get errorDekLocked =>
      'Archiv gesperrt. Entsperren Sie mit Ihrem Passwort.';

  @override
  String get errorRecoveryFailed =>
      'Wiederherstellung fehlgeschlagen. Überprüfen Sie Ihren Wiederherstellungscode.';

  @override
  String get errorWeakPassword =>
      'Das Passwort erfüllt nicht die Sicherheitsanforderungen';

  @override
  String get errorTotpSetupRequired =>
      'Ihr Konto erfordert eine zweistufige Überprüfung: Richten Sie es aus dem Web ein, bevor Sie sich von der App aus anmelden';

  @override
  String get errorChatNotConfigured => 'KI-Chat nicht konfiguriert';

  @override
  String errorChatLlmError(String detail) {
    return 'Fehler des KI-Modells: $detail';
  }

  @override
  String get errorNotFound => 'Nicht gefunden';

  @override
  String get errorPreviewUnsupported =>
      'Vorschau nicht verfügbar für dieses Format';

  @override
  String get errorPreviewFailed => 'konnte die Vorschau nicht erzeugen';

  @override
  String get errorRawMissing => 'Datei nicht mehr verfügbar';

  @override
  String get errorValidation => 'Ungültige Daten';

  @override
  String get errorNetwork => 'Netzwerkfehler. Überprüfen Sie Ihre Verbindung.';

  @override
  String get errorGeneric => 'Unerwarteter Fehler';

  @override
  String get errorFollowupNotRemindable =>
      'Für diese ausstehende Antwort kann keine Erinnerung mehr gesendet werden.';

  @override
  String get errorFollowupNotConfigured =>
      'Das Analysemodell ist auf diesem Server nicht konfiguriert.';

  @override
  String get errorFollowupDraftFailed =>
      'Die Erinnerung konnte nicht erstellt werden. Versuchen Sie es erneut.';

  @override
  String get errorFollowupSendNoSource =>
      'Kein Ursprungskonto, das diese Nachricht senden kann.';

  @override
  String get errorSendConsentRequired =>
      'Das Microsoft 365-Konto muss von der Web-App erneut zum Senden autorisiert werden.';

  @override
  String get errorMailAuthFailed =>
      'Die Authentifizierung gegenüber dem E-Mail-Konto ist fehlgeschlagen.';

  @override
  String get errorMailSendFailed =>
      'Senden fehlgeschlagen. Versuchen Sie es später erneut.';

  @override
  String get navFollowups => 'Ausstehende Antworten';

  @override
  String get followupsTitle => 'Ausstehende Antworten';

  @override
  String get followupsTabTheirTurn => 'Warten auf die Antwort';

  @override
  String get followupsTabMyTurn => 'Zu beantworten';

  @override
  String get followupsEmpty => 'Keine offenen Erwartungen.';

  @override
  String get followupsRecentlyClosed => 'Vor kurzem geschlossen';

  @override
  String get followupsLoadMore => 'Mehr laden';

  @override
  String get followupsDisabledTitle => 'Feature nicht aktiviert';

  @override
  String get followupsDisabledBody =>
      'Aktivieren Sie ausstehende Antworten in Ihrem Profil in der Web-App.';

  @override
  String get followupsUnavailableTitle =>
      'Erfordert einen aktualisierten Server';

  @override
  String get followupsUnavailableBody =>
      'Dieser Server bietet die Verwaltung ausstehender Antworten noch nicht an.';

  @override
  String get followupsPausedEndpoint =>
      'Analyse pausiert: Der KI-Endpunkt antwortet nicht. Das Archiv wird weiterhin synchronisiert.';

  @override
  String get followupsPausedCap => 'Analyse pausiert: Tageslimit erreicht.';

  @override
  String get followupsPausedBilling =>
      'Analyse pausiert: KI-Limit des Tarifs erreicht.';

  @override
  String get followupsActionOpen => 'Unterhaltung öffnen';

  @override
  String get followupsActionReminder => 'Erinnerung vorbereiten';

  @override
  String get followupsActionDone => 'Fertig';

  @override
  String get followupsActionSnooze1 => 'Um 1 Tag verschieben';

  @override
  String get followupsActionSnooze3 => 'Um 3 Tage verschieben';

  @override
  String get followupsActionDismiss => 'Ignorieren';

  @override
  String get followupsActionError => 'Aktion fehlgeschlagen';

  @override
  String get followupsChipAnswered => 'Beantwortet';

  @override
  String get followupsChipDismissed => 'Ignoriert';

  @override
  String followupsChipSnoozed(String date) {
    return 'Verschoben bis $date';
  }

  @override
  String followupsChipReminded(String date) {
    return 'Erinnerung gesendet am $date';
  }

  @override
  String followupsChipRemindedMany(String date, int count) {
    return 'Erinnerung gesendet am $date ×$count';
  }

  @override
  String followupsChipOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Seit $days Tagen überfällig',
      one: 'Seit 1 Tag überfällig',
    );
    return '$_temp0';
  }

  @override
  String get followupsChipDueToday => 'Heute fällig';

  @override
  String get followupsChipDueTomorrow => 'Morgen fällig';

  @override
  String followupsChipDueOn(String date) {
    return 'Fällig am $date';
  }

  @override
  String get reminderTitle => 'Erinnerung vorbereiten';

  @override
  String get reminderGenerating => 'Generierung des Entwurfs...';

  @override
  String get reminderFailed => 'Konnte den Entwurf nicht erzeugen.';

  @override
  String get reminderSubject => 'Betreff';

  @override
  String get reminderMessage => 'Nachricht';

  @override
  String get reminderRegister => 'Anredeform';

  @override
  String get reminderRegisterAuto => 'Auto';

  @override
  String get reminderRegisterTu => 'Informell';

  @override
  String get reminderRegisterLei => 'Formal';

  @override
  String reminderRegisterUsed(String register, String source) {
    return 'Anredeform: $register ($source)';
  }

  @override
  String get reminderRegisterSourceManual => 'gewählt';

  @override
  String get reminderRegisterSourceContact => 'für diesen Kontakt gespeichert';

  @override
  String get reminderRegisterSourceDetected => 'anhand Ihres Stils erkannt';

  @override
  String get reminderRegisterSourceDefault => 'Standard';

  @override
  String get reminderRememberContact => 'Für diesen Kontakt speichern';

  @override
  String get reminderRemembered => 'Anredeform für diesen Kontakt gespeichert';

  @override
  String get reminderLanguage => 'Sprache';

  @override
  String get reminderLanguageAuto => 'Auto';

  @override
  String get reminderInstructionsHint =>
      'Anweisungen für die Neuerstellung (optional)';

  @override
  String get reminderRegenerate => 'Neu erstellen';

  @override
  String get reminderExpand => 'Vollständiger Bildschirm';

  @override
  String get reminderInstructions => 'Anweisungen';

  @override
  String get reminderIncludeOriginal =>
      'Zitieren Sie die ursprüngliche E-Mail am Ende';

  @override
  String get reminderAppendedNote =>
      'Signatur, KI-Hinweis und gegebenenfalls das Originalzitat werden automatisch angefügt.';

  @override
  String reminderSendFromNote(String from) {
    return 'Die E-Mail wird von Ihrem Konto $from gesendet';
  }

  @override
  String get reminderPreview => 'E-Mail-Vorschau';

  @override
  String get reminderPreviewTitle => 'E-Mail-Vorschau';

  @override
  String get reminderSendNow => 'Senden von CercaPosta';

  @override
  String reminderSent(String from) {
    return 'Erinnerung gesendet von $from';
  }

  @override
  String notifFollowupNoReplyTitle(String name) {
    return '$name hat nicht geantwortet';
  }

  @override
  String notifFollowupNoReplyBody(String summary, int days) {
    return '«$summary» — seit $days Tagen keine Antwort.';
  }

  @override
  String notifFollowupReplyDueTitle(String name) {
    return 'Sie sollten auf $name antworten';
  }

  @override
  String notifFollowupReplyDueBody(String summary, int days) {
    return '«$summary» — die Frist ist seit $days Tagen abgelaufen.';
  }

  @override
  String get notifChannelName => 'Benachrichtigungen';

  @override
  String notifSummaryTitle(int count) {
    return '$count neue Benachrichtigungen';
  }

  @override
  String get notifSummaryBody => 'Öffnen Sie CercaPosta, um sie alle zu sehen.';

  @override
  String get notifFollowupDueSoonTitle => 'Näher rückende Frist';

  @override
  String notifFollowupDueSoonBody(String summary, String name, String date) {
    return '«$summary» — $name: fällig am $date.';
  }

  @override
  String notifFollowupReminderSentTitle(String name) {
    return 'Erinnerung an $name gesendet';
  }

  @override
  String notifFollowupReminderSentBody(String summary) {
    return '« $summary » — die automatische Erinnerung wurde gesendet.';
  }

  @override
  String get notifFollowupDigestTitle =>
      'Zusammenfassung der Antworterwartungen';

  @override
  String notifFollowupDigestBody(int overdue, int dueToday, int waitingMe) {
    return '$overdue überfällig · $dueToday heute fällig · $waitingMe ausstehende eigene Antworten.';
  }

  @override
  String get notifOpenConversation => 'Unterhaltung öffnen';

  @override
  String get actionCopy => 'Kopieren';

  @override
  String get actionCopied => 'In die Zwischenablage kopiert';

  @override
  String get emailHeadersTitle => 'Nachrichtenkopfzeilen';

  @override
  String get emailHeadersEmpty => 'Keine Header verfügbar';

  @override
  String get followupMarkTitle => 'Als ausstehende Antwort markieren';

  @override
  String get followupMarkTheirTurn => 'Ich warte auf eine Antwort';

  @override
  String get followupMarkTheirTurnHint =>
      'Ich habe geschrieben und warte darauf, dass sie antworten.';

  @override
  String get followupMarkMyTurn => 'Ich schulde eine Antwort';

  @override
  String get followupMarkMyTurnHint =>
      'Ich habe eine Nachricht erhalten und bin mit der Antwort an der Reihe';

  @override
  String get followupMarkDue => 'Frist (optional)';

  @override
  String get followupMarkPickDue => 'Wählen Sie ein Datum';

  @override
  String get followupMarkConfirm => 'Erstellen';

  @override
  String get followupMarkCreated => 'Als ausstehende Antwort markiert';

  @override
  String get errorFollowupAlreadyActive =>
      'Es gibt bereits eine offene Erwartung an dieses Gespräch.';

  @override
  String get errorFollowupNoCounterpart =>
      'Kann nicht sagen, wer antworten soll: versuchen Sie die andere Richtung.';

  @override
  String get memoryTitle => 'Chat-Gedächtnis';

  @override
  String get memorySettingsHint => 'Was der Assistent über Sie gelernt hat';

  @override
  String get memoryIntro =>
      'Hier steht alles, was der Assistent über Sie gelernt hat: wie Sie Personen nennen, wie Sie Auflistungen wünschen und welche Fakten er voraussetzt. Sie können jeden Eintrag pausieren oder löschen. Nichts wird ohne einen Hinweis an Sie gelernt. Um einen Eintrag hinzuzufügen, schreiben Sie im Chat: «Merken Sie sich, dass…».';

  @override
  String get memoryPolicyLearn => 'Lernen Sie aus meinen Gesprächen';

  @override
  String get memoryPolicyLearnHint =>
      'Wenn diese Option aktiviert ist, schlägt der Assistent vor, was er während Ihrer Zusammenarbeit bemerkt. Er informiert Sie jedes Mal, und Sie können dies rückgängig machen. Wenn Sie die Option deaktivieren, bleiben nur die von Ihnen selbst eingegebenen Einträge erhalten.';

  @override
  String get memoryPolicyEnabled => 'Verwenden Sie das Gedächtnis in Antworten';

  @override
  String get memoryPolicyEnabledHint =>
      'Wenn Sie diese Option deaktivieren, bleiben alle Einträge erhalten, werden aber nicht mehr angewendet. Sie werden pausiert, nicht gelöscht.';

  @override
  String memoryAnnounceAlias(String key, String value) {
    return 'Ich habe gelernt, dass für Sie « $key » bedeutet $value .';
  }

  @override
  String memoryAnnounceGeneric(String key, String value) {
    return 'Ich habe gelernt: $key → $value .';
  }

  @override
  String memoryAnnounceTrial(String what) {
    return '$what Ich behalte diesen Eintrag vorerst zur Erprobung und verwende ihn noch nicht.';
  }

  @override
  String get memoryAnnounceUndo => 'Rückgängig';

  @override
  String get memoryAnnounceUndone =>
      'Rückgängig gemacht: Ich habe den Eintrag nicht behalten.';

  @override
  String get memoryAnnounceRejected =>
      'In Ordnung, ich werde es nicht noch einmal vorschlagen.';

  @override
  String memoryAppliedNote(String list) {
    return 'Aus dem Speicher: $list';
  }

  @override
  String get memoryListEmpty =>
      'Noch keine Einträge im Gedächtnis. Schreiben Sie im Chat: «Merken Sie sich, dass…».';

  @override
  String get memoryListEmptyFiltered => 'Keine Erinnerungen in diesem Zustand.';

  @override
  String get memoryFilterAll => 'Alle';

  @override
  String get memoryFilterActive => 'Aktiv';

  @override
  String get memoryFilterTrial => 'Zur Erprobung';

  @override
  String get memoryFilterRejected => 'Verweigert';

  @override
  String get memoryFilterDisabled => 'Angehalten';

  @override
  String get memoryStatusActive => 'Aktiv';

  @override
  String get memoryStatusTrial => 'Zur Erprobung';

  @override
  String get memoryStatusRejected => 'Verweigert';

  @override
  String get memoryStatusDisabled => 'Angehalten';

  @override
  String get memoryStatusTrialHint =>
      'wird noch erlernt und noch nicht verwendet';

  @override
  String get memoryStatusStaleHint =>
      'Monatelang unbenutzt: pausieren, wenn Sie es nicht mehr brauchen';

  @override
  String get memoryKindAlias => 'Wie Sie Personen nennen';

  @override
  String get memoryKindParam => 'Wie Sie suchen möchten';

  @override
  String get memoryKindRender => 'Wie Sie Auflistungen wünschen';

  @override
  String get memoryKindFact => 'Fakten, die man im Auge behalten sollte';

  @override
  String get memoryKindShortcut => 'Wiederkehrende Fragen';

  @override
  String get memoryTriggerSearch => 'bei der Suche';

  @override
  String get memoryTriggerListing => 'in Auflistungen';

  @override
  String get memoryTriggerContact => 'über Kontakte';

  @override
  String get memoryTriggerAlways => 'immer';

  @override
  String get memorySourceExplicit => 'Sie sagten:';

  @override
  String get memorySourceCorrection => 'aus einer Ihrer Korrekturen';

  @override
  String get memorySourceRecurrence => 'Aus einer Gewohnheit';

  @override
  String get memorySourceSuggested => 'vom Archiv vorgeschlagen';

  @override
  String get memorySourceInferred =>
      'aus etwas abgeleitet, das Sie geschrieben haben';

  @override
  String memoryUsedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-mal verwendet',
      one: 'einmal verwendet',
    );
    return '$_temp0';
  }

  @override
  String get memoryEnable => 'Fortsetzen';

  @override
  String get memoryDisable => 'Pause';

  @override
  String get memoryReject => 'Dies nie speichern';

  @override
  String get memoryUnreject => 'Ich änderte meine Meinung';

  @override
  String get memoryDelete => 'Löschen';

  @override
  String memoryDeleteConfirm(String key) {
    return 'Eintrag «$key» löschen? Wenn er nie wieder vorgeschlagen werden soll, wählen Sie «Dies nie speichern».';
  }

  @override
  String get memorySuggestionsTitle =>
      'Aliases, die von Ihrem Archiv vorgeschlagen werden';

  @override
  String get memorySuggestionsHint =>
      'Namen, die in Ihrem Archiv eindeutig einer Person zugeordnet sind. Wenn Sie einen Vorschlag annehmen, sucht der Chat direkt nach der zugehörigen Adresse, sobald Sie diesen Namen nennen.';

  @override
  String get memorySuggestionsAccept => 'Akzeptieren';

  @override
  String memorySuggestionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count E-Mails',
      one: '1 E-Mail',
    );
    return '$_temp0';
  }

  @override
  String get diagnosticsTitle => 'Diagnose';

  @override
  String get diagnosticsIntro =>
      'Ob alles, was importiert wurde, tatsächlich durchsuchbar ist. Wenn etwas fehlt, bekommen Sie den Grund und, wo es einen gibt, was Sie dagegen tun können.';

  @override
  String get diagnosticsStatusOk =>
      'Alles gut: Das Archiv ist vollständig und durchsuchbar.';

  @override
  String get diagnosticsStatusWorking =>
      'Die Verarbeitung läuft noch: Ein Teil des Archivs ist noch nicht durchsuchbar. Sie müssen nichts unternehmen.';

  @override
  String get diagnosticsStatusAttention =>
      'Prüfen Sie die unten aufgeführten Hinweise.';

  @override
  String get diagnosticsMessages => 'Nachrichten in der KI-Suche';

  @override
  String get diagnosticsAttachments => 'Text gelesen in Anhängen';

  @override
  String diagnosticsOf(String done, String total) {
    return '$done von $total';
  }

  @override
  String diagnosticsAttachmentsPending(String n) {
    return '$n Anhänge in der Warteschlange';
  }

  @override
  String diagnosticsMessagesPending(String n) {
    return '$n Nachrichten in der Warteschlange';
  }

  @override
  String get diagnosticsEmbeddingOff => 'KI-Suche deaktiviert';

  @override
  String get diagnosticsEmbeddingPaused => 'pausiert: KI-Plan Limits';

  @override
  String get diagnosticsEmbeddingActive => 'Warteschlange läuft';

  @override
  String diagnosticsEmbeddingLastError(String when, String detail) {
    return 'letzter Fehler ( $when ): $detail';
  }

  @override
  String diagnosticsRetryAll(String n) {
    return 'Bei $n Anhängen erneut versuchen';
  }

  @override
  String get diagnosticsRetryHint =>
      'Die Verarbeitung wurde durch einen vorübergehenden Fehler gestoppt. Ein neuer Versuch kann erfolgreich sein.';

  @override
  String diagnosticsRetryExhaustedHint(String n) {
    return '$n dieser Anhänge haben bereits alle fünf automatischen Versuche verbraucht. Ein neuer Versuch ist sinnvoll, wenn die Ursache der Unterbrechung behoben wurde.';
  }

  @override
  String diagnosticsReasonsTitle(String n) {
    return 'Warum $n Anhänge keinen Text haben';
  }

  @override
  String diagnosticsExpectedTitle(String n) {
    return '$n-Anhänge waren keine Dokumente zum Lesen';
  }

  @override
  String diagnosticsEmbedReasonsTitle(String n) {
    return 'Warum $n-Nachrichten es nicht in die KI-Suche geschafft haben';
  }

  @override
  String get diagnosticsActionRetry => 'Erneut versuchen';

  @override
  String get diagnosticsActionAskAdmin => 'Administrator erforderlich';

  @override
  String get diagnosticsActionNone => 'Nichts zu tun';

  @override
  String get diagnosticsReasonTikaHttpError =>
      'Der Dokumentenleser reagierte nicht';

  @override
  String get diagnosticsReasonTikaTimeout => 'Das Dokument dauerte zu lange';

  @override
  String get diagnosticsReasonTikaServerError =>
      'Der Dokumentenleser hat einen Fehler zurückgegeben';

  @override
  String get diagnosticsReasonTikaBusy =>
      'Der Dokumentenleser ist vorübergehend beschäftigt';

  @override
  String get diagnosticsReasonTikaPartial =>
      'Nur ein Teil des Dokumenttextes wurde wiederhergestellt';

  @override
  String get diagnosticsReasonTikaInvalidLimits =>
      'Die Extraktionslimits sind ungültig: Kontaktieren Sie den Administrator';

  @override
  String get diagnosticsReasonTikaRejected =>
      'Der Dokumentenleser lehnte die Datei ab';

  @override
  String get diagnosticsReasonTikaUnsupported =>
      'Ein Dateityp, den ich nicht lesen kann';

  @override
  String get diagnosticsReasonExtractBacklogError =>
      'Unerwarteter Fehler beim Lesen';

  @override
  String get diagnosticsReasonUnmatchedPart =>
      'Anlage, die in der Nachricht nicht gefunden wurde';

  @override
  String get diagnosticsReasonOverSizeLimit => 'Größer als das erlaubte Limit';

  @override
  String get diagnosticsReasonEmpty => 'Leere Datei';

  @override
  String get diagnosticsReasonSignatureFile =>
      'Digitale Signatur, kein Dokument';

  @override
  String get diagnosticsReasonInlineImage =>
      'Bild eingebettet in die Nachricht (Logo, Signatur)';

  @override
  String get diagnosticsReasonUnknown => 'Ursache nicht erfasst';

  @override
  String get diagnosticsSettingsHint =>
      'Ob alles, was Sie importiert haben, wirklich durchsuchbar ist und was fehlt';

  @override
  String get billingTitle => 'Tarif und Zahlungen';

  @override
  String get billingSettingsHint =>
      'Aktueller Tarif, Verlängerung und geplante Änderungen';

  @override
  String get billingCurrentPlan => 'Aktueller Tarif';

  @override
  String get billingNoPlan => 'Kein aktiver Tarif.';

  @override
  String get billingStatus => 'Status';

  @override
  String get billingPaymentMethod => 'Zahlungsmethode';

  @override
  String get billingRecurringPrice => 'Wiederkehrender Preis';

  @override
  String get billingPeriodEnd => 'Periodenende';

  @override
  String get billingPlanValidity => 'Gültigkeit des Tarifs';

  @override
  String get billingNoExpiration => 'Kein Ablauf';

  @override
  String get billingPeriodicity => 'Abrechnungshäufigkeit';

  @override
  String get billingIntervalMonthly => 'Monatlich';

  @override
  String get billingIntervalAnnual => 'Jährlich';

  @override
  String get billingNextRenewal => 'Nächste Erneuerung';

  @override
  String get billingNextRenewalAmount => 'Nächster Verlängerungsbetrag';

  @override
  String get billingDateUnavailable => 'Datum noch nicht verfügbar';

  @override
  String get billingGraceUntil => 'Nachfrist bis';

  @override
  String get billingPendingChanges => 'Tarifänderungen';

  @override
  String get billingEffectiveAt => 'Datum des Inkrafttretens';

  @override
  String get billingAmountDue => 'Voraussichtlicher Betrag';

  @override
  String get billingManageInBrowser => 'Tarif und Zahlungen verwalten';

  @override
  String get billingExternalCheckoutHint =>
      'Zum Schutz Ihrer Zahlung erfolgen Kaufabschluss, erneute Zahlungsversuche und Stornierungen im sicheren Browserbereich von CercaPosta.';

  @override
  String get billingStatusActive => 'Aktiv';

  @override
  String get billingStatusFree => 'Kostenlos';

  @override
  String get billingStatusPastDue => 'Überfällige Zahlungen';

  @override
  String get billingStatusSuspended => 'ausgesetzt';

  @override
  String get billingStatusCanceled => 'Storniert';

  @override
  String get billingProviderManual => 'Manuelle Zahlung';

  @override
  String get billingChangePendingAcceptance => 'Warten auf Ihre Annahme';

  @override
  String get billingChangePendingPayment => 'Warten auf Zahlung';

  @override
  String get billingChangeScheduled => 'Geplant';

  @override
  String get billingChangeProcessing => 'Verarbeitung';

  @override
  String get billingChangePaymentGrace => 'Zahlung fehlgeschlagen · Nachfrist';

  @override
  String get billingChangeCanceling => 'Annullierung im Gange';

  @override
  String get notifPlanChangeProposalTitle =>
      'Sie haben einen Plan-Änderungsvorschlag';

  @override
  String get notifPlanChangeProposalBody =>
      'Öffnen Sie „Tarif und Zahlungen“, um Preis, Guthaben und Wirksamkeitsdatum zu prüfen.';

  @override
  String get notifPlanChangeProposalExpiringTitle =>
      'Der Vorschlag läuft bald aus';

  @override
  String notifPlanChangeProposalExpiringBody(String date) {
    return 'Prüfen Sie den Vorschlag bis zum $date.';
  }

  @override
  String get notifPlanChangeExpiredTitle => 'Die Tarifänderung ist abgelaufen';

  @override
  String get notifPlanChangeExpiredBody =>
      'Die Änderung wurde nicht angewendet und Ihr vorheriger Plan blieb unverändert.';

  @override
  String get notifPlanChangeScheduledTitle => 'Die Planänderung ist geplant';

  @override
  String notifPlanChangeScheduledBody(String date) {
    return 'Die Änderung wird am $date wirksam. Ihr aktueller Tarif bleibt bis dahin aktiv.';
  }

  @override
  String get notifPlanChangeAppliedTitle => 'Ihr neuer Plan ist aktiv';

  @override
  String get notifPlanChangeAppliedBody =>
      'Ihre neuen Kontingente und Funktionen sind jetzt verfügbar.';

  @override
  String get notifPlanChangeCanceledTitle =>
      'Die Tarifänderung wurde storniert';

  @override
  String get notifPlanChangeCanceledBody =>
      'Ihr aktueller Plan bleibt unverändert.';

  @override
  String get notifPlanChangePaymentFailedTitle =>
      'Die Zahlung ist fehlgeschlagen';

  @override
  String notifPlanChangePaymentFailedBody(String date) {
    return 'Ihr bisheriger Tarif bleibt aktiv. Versuchen Sie die Zahlung bis zum $date erneut.';
  }

  @override
  String get notifPlanChangeRetryTitle => 'Sie können die Zahlung wiederholen';

  @override
  String get notifPlanChangeRetryBody =>
      'Öffnen Sie „Tarif und Zahlungen“, um die Zahlung erneut zu versuchen.';

  @override
  String get notifPlanChangeGraceExpiringTitle => 'Die Nachfrist endet bald';

  @override
  String notifPlanChangeGraceExpiringBody(String date) {
    return 'Schließen Sie die Zahlung bis zum $date ab.';
  }

  @override
  String get notifPlanChangeGraceExpiredTitle => 'Die Nachfrist ist abgelaufen';

  @override
  String get notifPlanChangeGraceExpiredBody =>
      'Die Änderung wurde nicht angewendet, weil die Zahlung nicht abgeschlossen wurde.';

  @override
  String get notifPlanChangeActionRequiredTitle =>
      'Planänderung braucht Unterstützung';

  @override
  String get notifPlanChangeActionRequiredBody =>
      'Prüfen Sie „Tarif und Zahlungen“ oder wenden Sie sich an den Support.';

  @override
  String get passkeyUnsupportedServer =>
      'Passkeys sind für diesen Server in dieser App-Version nicht verfügbar. Verwenden Sie Ihr Passwort, Google oder Apple. Sie können Passkeys auf der Website des Servers verwalten.';

  @override
  String get searchVoiceLocalUnavailable =>
      'Die lokale Spracherkennung ist für diese Sprache oder dieses Gerät nicht verfügbar. Verwenden Sie die Tastatur. Android benötigt Android 12 oder neuer sowie einen installierten lokalen Spracherkennungsdienst.';

  @override
  String get deliveryHistory => 'Versandstatus';

  @override
  String get deliveryReference => 'Versandreferenz';

  @override
  String get deliverySending => 'Versendung';

  @override
  String get deliverySent => 'Vom E-Mail-Dienst angenommen';

  @override
  String get deliveryFailed => 'Nicht gesendet';

  @override
  String get deliveryUnknown => 'Ergebnis muss überprüft werden';

  @override
  String get deliveryChecked =>
      'Ich habe das Ergebnis beim E-Mail-Dienst geprüft und bestätigt, dass der Versuch nicht mehr läuft. Falls der Vorgang blockiert war, habe ich ihn stoppen lassen.';

  @override
  String get deliveryConfirmSent => 'Bestätigung der Annahme';

  @override
  String get deliveryConfirmFailed => 'Als nicht gesendet bestätigen';

  @override
  String get deliveryResolved =>
      'Ergebnis aufgezeichnet. Es wurde keine neue Nachricht gesendet.';

  @override
  String get deliveryEmpty => 'Es wurden keine Lieferversuche registriert.';

  @override
  String get errorDeliveryUnknown =>
      'Der E-Mail-Dienst hat die Nachricht möglicherweise angenommen. Prüfen Sie „Versandstatus“ und klären Sie das Ergebnis mit dem Anbieter, bevor Sie es erneut versuchen.';

  @override
  String get errorDeliverySending =>
      'Eine Zustellung für diese ausstehende Antwort ist bereits im Gange. Versuchen Sie es nicht noch einmal.';

  @override
  String get errorDeliveryConflict =>
      'Diese Anfrage wurde bereits bearbeitet oder enthält andere Inhalte. Prüfen Sie „Versandstatus“.';

  @override
  String get errorDeliveryCheckRequired =>
      'Überprüfen Sie das Ergebnis beim E-Mail-Dienst, bevor Sie es bestätigen.';

  @override
  String get errorMailNotAccepted =>
      'Der Versuch scheiterte vor der Annahme des Postdienstes. Beheben Sie das Problem und versuchen Sie es erneut.';

  @override
  String get errorMailDeliveryUnknown =>
      'Das Lieferergebnis ist ungewiss. Erkundigen Sie sich beim Postdienst, bevor Sie es erneut versuchen.';

  @override
  String get biometricErrorCancelled =>
      'Biometrische Überprüfung abgebrochen. Sie können sich mit Ihrem Passwort anmelden.';

  @override
  String get biometricErrorUnavailable =>
      'Die biometrisch geschützte Speicherung ist nicht verfügbar. Verwenden Sie Ihr Passwort. Wenn Sie Fingerabdrücke oder Face ID geändert haben, aktivieren Sie die Biometrie erneut in den Einstellungen.';

  @override
  String get biometricErrorReenroll =>
      'Diese Geräteberechtigung ist abgelaufen oder nicht mehr gültig. Melden Sie sich manuell an und aktivieren Sie die Biometrie erneut in den Einstellungen.';

  @override
  String get errorReauthenticationRequired =>
      'Melden Sie sich aus Sicherheitsgründen ab und mit Ihrer üblichen Methode wieder an. Aktivieren Sie die Biometrie anschließend innerhalb von 5 Minuten.';

  @override
  String get aiReportAction => 'Antwort melden';

  @override
  String get aiReportTitle => 'KI-Antwort melden';

  @override
  String get aiReportIntro =>
      'Die Antwort und Ihr Kommentar werden sicher an Administratoren zur Überprüfung gesendet.';

  @override
  String get aiReportReason => 'Grund';

  @override
  String get aiReportReasonMisleading => 'Irreführend oder falsch';

  @override
  String get aiReportReasonHarmful => 'Schädlich';

  @override
  String get aiReportReasonIllegal => 'Illegale Inhalte';

  @override
  String get aiReportReasonPrivacy => 'Datenschutzproblem';

  @override
  String get aiReportReasonOther => 'andere';

  @override
  String get aiReportComment => 'Optionaler Kommentar';

  @override
  String get aiReportCommentHint =>
      'Erklären Sie, was mit der Antwort falsch ist';

  @override
  String get aiReportSend => 'Versenden des Berichts';

  @override
  String get aiReportSent => 'Versendeter Bericht';

  @override
  String get aiReportAlreadySent => 'Diese Antwort wurde bereits gemeldet';

  @override
  String get tagsTitle => 'Tags';

  @override
  String get tagsAssignHint =>
      'Weisen Sie dieser Nachricht Tags zu oder verwalten Sie die verfügbaren Tags';

  @override
  String get tagsManageMessage => 'Tags verwalten';

  @override
  String get tagsEmpty => 'Sie haben noch keine Tags erstellt.';

  @override
  String get tagsCreate => 'Tag erstellen';

  @override
  String get tagsCreateTitle => 'Neuer Tag';

  @override
  String get tagsEdit => 'Bearbeiten';

  @override
  String get tagsEditTitle => 'Tag bearbeiten';

  @override
  String get tagsDelete => 'Löschen';

  @override
  String get tagsDeleteTitle => 'Tag löschen';

  @override
  String tagsDeleteConfirm(String name) {
    return 'Möchten Sie das Tag „$name“ aus dem gesamten Archiv löschen?';
  }

  @override
  String get tagsName => 'Name';

  @override
  String get actionDone => 'Fertig';

  @override
  String get errorTagNameRequired => 'Geben Sie einen Namen für das Tag ein.';

  @override
  String get errorTagNameTaken => 'Ein Tag mit diesem Namen existiert bereits.';

  @override
  String get errorTagInvalidColor => 'Die gewählte Farbe ist ungültig.';

  @override
  String get errorAiReportMessageNotFound =>
      'Diese Antwort kann nicht mehr gemeldet werden.';

  @override
  String get errorAiReportAssistantOnly =>
      'Nur Antworten des Assistenten können gemeldet werden.';

  @override
  String get settingsLanguageUiHint =>
      'Diese Wahl gilt nur für die Schnittstelle auf diesem Gerät.';

  @override
  String get settingsProfileLanguage =>
      'Sprache für E-Mails, Zahlungsbelege und KI-Antworten';

  @override
  String get settingsProfileLanguageHint =>
      'Wird für E-Mails, Zahlungsbelege und KI-Antworten verwendet. Bei freigegebenen Arbeitsbereichen gilt für Zahlungsbelege die Spracheinstellung des Inhabers. Die Sprache der Benutzeroberfläche sowie Datums- und Zahlenformate bleiben davon unabhängig. Bereits ausgestellte Belege bleiben unverändert.';

  @override
  String get searchVoiceChooseLanguage =>
      'Sprache und Variante für lokales Diktat';

  @override
  String get searchVoiceHint =>
      'Lokales Diktat. Drücken und halten, um eine Sprache und Variante zu wählen.';
}
