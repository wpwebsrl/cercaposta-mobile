// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Cerca posta';

  @override
  String get actionCancel => 'Annulla';

  @override
  String get actionConfirm => 'Conferma';

  @override
  String get actionClose => 'Chiudi';

  @override
  String get actionRetry => 'Riprova';

  @override
  String get actionSave => 'Salva';

  @override
  String get actionApply => 'Applica';

  @override
  String get actionClear => 'Pulisci';

  @override
  String get actionContinue => 'Continua';

  @override
  String get actionRemove => 'Rimuovi';

  @override
  String get actionOpenInBrowser => 'Apri nel browser';

  @override
  String get loading => 'Caricamento…';

  @override
  String get today => 'Oggi';

  @override
  String get yesterday => 'Ieri';

  @override
  String get serverTitle => 'Scegli il server';

  @override
  String get serverSubtitle =>
      'Inserisci l\'indirizzo del tuo server Cerca posta.';

  @override
  String get serverUrlLabel => 'Indirizzo server';

  @override
  String get serverUrlHint => 'https://mail.esempio.it';

  @override
  String get serverValidating => 'Validazione del server…';

  @override
  String get serverInvalid => 'Indirizzo non valido o server non raggiungibile';

  @override
  String get serverNotCercaPosta =>
      'Questo server non è un\'istanza Cerca posta';

  @override
  String get serverSavedTitle => 'Server salvati';

  @override
  String get serverNeedsSetup => 'Questo server va ancora configurato dal web.';

  @override
  String get serverUpdateRequired => 'Aggiorna l\'app per usare questo server.';

  @override
  String get loginTitle => 'Accedi';

  @override
  String get loginUsername => 'Nome utente';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginButton => 'Accedi';

  @override
  String get loginChangeServer => 'Cambia server';

  @override
  String get loginBiometric => 'Accedi con la biometria';

  @override
  String get loginBiometricReason => 'Accedi al tuo archivio email';

  @override
  String get loginEnableBiometricTitle => 'Accesso rapido';

  @override
  String get loginEnableBiometricBody =>
      'Vuoi accedere con Face ID / impronta la prossima volta? Le credenziali vengono salvate in modo sicuro sul dispositivo.';

  @override
  String sharedFromLabel(String name) {
    return 'da $name';
  }

  @override
  String sharedReaderBanner(String name) {
    return 'Cartella condivisa da $name — sola lettura';
  }

  @override
  String get totpTitle => 'Verifica in due passaggi';

  @override
  String get totpSubtitle => 'Inserisci il codice dell\'app di autenticazione.';

  @override
  String get totpCode => 'Codice a 6 cifre';

  @override
  String get totpButton => 'Verifica';

  @override
  String get unlockTitle => 'Sblocca archivio';

  @override
  String get unlockDescription =>
      'Il tuo archivio è cifrato. Inserisci la password per accedere ai contenuti.';

  @override
  String get unlockPassword => 'Password';

  @override
  String get unlockButton => 'Sblocca';

  @override
  String get unlockBiometric => 'Sblocca con la biometria';

  @override
  String get unlockEnableBiometricTitle => 'Sblocco rapido';

  @override
  String get unlockEnableBiometricBody =>
      'Vuoi sbloccare l\'archivio con la biometria ai prossimi avvii? La password viene salvata in modo sicuro sul dispositivo.';

  @override
  String get unlockEnableBiometricYes => 'Sì, abilita';

  @override
  String get unlockEnableBiometricNo => 'No, grazie';

  @override
  String get unlockReason => 'Sblocca il tuo archivio cifrato';

  @override
  String get firstPasswordTitle => 'Imposta nuova password';

  @override
  String get firstPasswordSubtitle =>
      'Al primo accesso devi scegliere una password personale (l\'amministratore non la conoscerà).';

  @override
  String get firstPasswordNew => 'Nuova password';

  @override
  String get firstPasswordConfirm => 'Conferma password';

  @override
  String get firstPasswordMismatch => 'Le password non coincidono';

  @override
  String get kitTitle => 'Kit di emergenza';

  @override
  String get kitBody =>
      'Conserva questo codice in un luogo sicuro: serve a recuperare l\'archivio se dimentichi la password. Viene mostrato SOLO ora.';

  @override
  String get kitCopy => 'Copia';

  @override
  String get kitCopied => 'Copiato negli appunti';

  @override
  String get recoveryTitle => 'Recupero archivio';

  @override
  String get recoverySubtitle =>
      'La password è stata reimpostata dall\'amministratore. Inserisci il codice del kit di emergenza e scegli una nuova password.';

  @override
  String get recoverySecretLabel => 'Codice di recupero';

  @override
  String get navSearch => 'Cerca';

  @override
  String get navChat => 'Chat AI';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get navNotifications => 'Notifiche';

  @override
  String get notificationsTitle => 'Notifiche';

  @override
  String get notificationsEmpty => 'Nessuna notifica.';

  @override
  String get notificationsDismiss => 'Ignora';

  @override
  String get notifReprocessTitle =>
      'Rielabora l\'archivio per adattarlo agli aggiornamenti';

  @override
  String get notifReprocessBody =>
      'Un aggiornamento dell\'app ha migliorato il modo in cui vengono gestite le email già in archivio (ad esempio le immagini incorporate nelle firme non contano più come allegati). La rielaborazione dell\'archivio si avvia dall\'app web.';

  @override
  String get searchHint => 'Cerca… (da:, tag:, ha:pdf…)';

  @override
  String get searchVoice => 'Ricerca vocale';

  @override
  String get searchVoiceListening => 'In ascolto…';

  @override
  String get searchVoiceUnavailable => 'Riconoscimento vocale non disponibile';

  @override
  String get searchVoicePermission => 'Permesso microfono negato';

  @override
  String get searchFilters => 'Filtri';

  @override
  String get searchNoResults => 'Nessun risultato';

  @override
  String get searchLoading => 'Ricerca in corso…';

  @override
  String get searchEmptyPrompt =>
      'Cerca nel tuo archivio per parole chiave o con gli operatori.';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count risultati',
      one: '1 risultato',
      zero: 'Nessun risultato',
    );
    return '$_temp0';
  }

  @override
  String attachmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allegati',
      one: '1 allegato',
    );
    return '$_temp0';
  }

  @override
  String get filtersTitle => 'Filtri';

  @override
  String get filterFrom => 'Da';

  @override
  String get filterTo => 'A / CC';

  @override
  String get filterSubject => 'Oggetto';

  @override
  String get filterHasAttachments => 'Con allegati';

  @override
  String get filterAttachmentExt => 'Tipo allegato (es. pdf)';

  @override
  String get filterDateFrom => 'Dopo il';

  @override
  String get filterDateTo => 'Prima del';

  @override
  String get filterTags => 'Tag';

  @override
  String get filterFolders => 'Cartelle';

  @override
  String get foldersTitle => 'Cartelle';

  @override
  String get foldersAll => 'Tutte le cartelle';

  @override
  String get foldersRefresh => 'Aggiorna';

  @override
  String get foldersEmpty => 'Nessuna cartella nell\'archivio';

  @override
  String get foldersExpand => 'Espandi';

  @override
  String get foldersCollapse => 'Comprimi';

  @override
  String foldersMultiple(int count) {
    return '$count cartelle';
  }

  @override
  String get aboutTitle => 'Informazioni';

  @override
  String get aboutCompany => 'WpWeb S.r.l.';

  @override
  String get aboutBuildLabel => 'build';

  @override
  String get aboutWebsite => 'Visita wpweb.com';

  @override
  String get aboutCredits =>
      'Cerca posta è un prodotto WpWeb: archivio email intelligente, cifrato e ricercabile.\nTutte le tue email, finalmente in un unico posto.\nAnni di messaggi, conversazioni e allegati, raccolti e messi in ordine.\nNiente più caselle sparse, vecchi backup o file dimenticati.\nCerca posta riunisce tutto in un archivio sicuro, sempre a portata di mano.\nTrovare un\'email non è più una caccia al tesoro.\nScrivi quello che ricordi, come lo diresti a voce.\nUn nome, una data, una parola: i risultati arrivano in un istante.\nE se non ricordi le parole esatte? Nessun problema.\nCerca posta capisce il significato di ciò che cerchi, non solo le parole.\nCerchi «il preventivo dell\'idraulico dell\'anno scorso»?\nLo trova, anche se in quell\'email la parola «preventivo» non c\'era.\nC\'è anche un assistente intelligente che legge le email al posto tuo.\nFagli domande con parole tue e ricevi risposte chiare.\n«Quando ho confermato l\'appuntamento dal dentista?»\n«Qual è l\'IBAN che mi ha mandato il fornitore?»\nRisponde citando le email giuste, così puoi sempre verificare di persona.\nAnche gli allegati diventano cercabili.\nPDF, documenti, fogli di calcolo e persino il testo dentro le immagini.\nQuella fattura, quel contratto, quella foto: a portata di ricerca.\nBasta ore passate a scorrere la posta in cerca di un dettaglio.\nFiltra per cartella, per etichetta, per mittente o per periodo.\nRestringi la ricerca con pochi clic e vai dritto al punto.\nOgni messaggio si apre pulito e ben leggibile.\nE la cosa più importante: i tuoi dati restano tuoi, e solo tuoi.\nTutto è cifrato a riposo con la tua chiave personale.\nUn database o un backup rubati restano illeggibili.\nLa chiave di sicurezza è soltanto tua.\nCerca posta è un archivio in sola lettura.\nNon invia, non risponde e non modifica nulla nelle caselle di origine.\nConserva e protegge, senza mai toccare la fonte.\nÈ pensato per chi ha tante email e poco tempo.\nProfessionisti, aziende, studi, uffici e amministrazioni.\nÈ semplice da usare per chiunque.\nNessun manuale, nessuna complicazione.\nApri, scrivi cosa cerchi, trova. Tutto qui.\nLa memoria della tua corrispondenza, sempre con te.\nQuello che ti serve, esattamente quando ti serve.\nRitrova in pochi secondi ciò che credevi perso per sempre.\nRecupera informazioni, accordi e decisioni prese via email.\nTrasforma anni di posta in una risorsa viva e consultabile.\nPiù ordine, meno stress.\nPiù tempo per ciò che conta davvero.\nVeloce quando cerchi, discreto quando custodisce.\nAffidabile ogni volta che ti serve.\nSicuro per progettazione, semplice per scelta.\nIl tuo archivio email, intelligente e protetto.\nCercabile in tutto, comprensibile da subito.\nCerca posta: ritrova tutto, non perdere niente.\nUn prodotto WpWeb.\nTecnologia che semplifica la vita digitale.\nGrazie per aver scelto Cerca posta.';

  @override
  String get emailLoading => 'Caricamento messaggio…';

  @override
  String get emailNoBody => 'Nessun contenuto da mostrare.';

  @override
  String get emailRawMissing =>
      'Il messaggio originale non è più disponibile: vengono mostrati solo i metadati.';

  @override
  String get emailAttachments => 'Allegati';

  @override
  String get emailThread => 'Conversazione';

  @override
  String get emailOpenAttachment => 'Apri allegato';

  @override
  String get emailShowRemoteImages => 'Mostra immagini remote';

  @override
  String get emailPecBadge => 'PEC';

  @override
  String get emailTo => 'A';

  @override
  String get emailCc => 'CC';

  @override
  String get emailDate => 'Data';

  @override
  String get attachmentLoading => 'Caricamento anteprima…';

  @override
  String get attachmentUnsupported =>
      'Anteprima non disponibile per questo tipo di file.';

  @override
  String get chatTitle => 'Chat AI';

  @override
  String get chatHint => 'Fai una domanda sull\'archivio…';

  @override
  String get chatSend => 'Invia';

  @override
  String get chatNotConfigured =>
      'La chat AI non è configurata su questo server.';

  @override
  String get chatDisabled => 'La chat AI è disattivata su questo server.';

  @override
  String get chatNew => 'Nuova conversazione';

  @override
  String get chatHistory => 'Cronologia';

  @override
  String get chatHistoryEmpty => 'Nessuna conversazione salvata.';

  @override
  String get chatCitations => 'Fonti';

  @override
  String get chatPhaseUnderstanding => 'Comprensione…';

  @override
  String get chatPhaseSearching => 'Ricerca…';

  @override
  String get chatPhaseEmbedding => 'Analisi semantica…';

  @override
  String get chatPhaseReranking => 'Riordino…';

  @override
  String get chatPhaseGenerating => 'Generazione risposta…';

  @override
  String get chatEmbeddingFailed =>
      'Ricerca semantica non disponibile: risultati basati sulle sole parole chiave.';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsLanguageIt => 'Italiano';

  @override
  String get settingsLanguageEn => 'Inglese';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeLight => 'Chiaro';

  @override
  String get settingsThemeDark => 'Scuro';

  @override
  String get settingsThemeAuto => 'Automatico';

  @override
  String get settingsBiometric => 'Accesso e sblocco con biometria';

  @override
  String get settingsBiometricEnablePrompt =>
      'Inserisci la password del tuo account per abilitare l\'accesso e lo sblocco con la biometria.';

  @override
  String get settingsSessions => 'Dispositivi e sessioni';

  @override
  String get settingsLogout => 'Esci';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String settingsVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get sessionsTitle => 'Dispositivi e sessioni';

  @override
  String get sessionsCurrent => 'Questo dispositivo';

  @override
  String get sessionsRevoke => 'Disconnetti';

  @override
  String get sessionsRevokeAll => 'Disconnetti tutti';

  @override
  String get sessionsRevokeAllConfirm =>
      'Disconnettere tutti i dispositivi? Dovrai accedere di nuovo su ognuno.';

  @override
  String get sessionsEmpty => 'Nessuna sessione attiva.';

  @override
  String sessionsLastSeen(String when) {
    return 'Ultimo accesso: $when';
  }

  @override
  String sessionsCreated(String when) {
    return 'Attiva dal: $when';
  }

  @override
  String sessionsIp(String ip) {
    return 'Indirizzo IP: $ip';
  }

  @override
  String get serverHttpsRequired =>
      'Il server deve usare HTTPS. Gli indirizzi http:// non sono ammessi.';

  @override
  String get serverRemoveSaved => 'Rimuovi dai server salvati';

  @override
  String get searchClear => 'Cancella la ricerca';

  @override
  String get searchLoadMoreError =>
      'Errore di caricamento. Tocca per riprovare.';

  @override
  String get filterSize => 'Dimensione';

  @override
  String get filterSizeGreater => 'maggiore di';

  @override
  String get filterSizeLess => 'minore di';

  @override
  String get filterAccount => 'Account (ID sorgente)';

  @override
  String get emailBcc => 'CCN';

  @override
  String get emailShareEml => 'Condividi email (.eml)';

  @override
  String get emailLinkError => 'Impossibile aprire il link';

  @override
  String get attachmentShare => 'Condividi';

  @override
  String get attachmentShareError => 'Impossibile condividere l\'allegato';

  @override
  String get chatStop => 'Interrompi';

  @override
  String get chatDelete => 'Elimina conversazione';

  @override
  String get chatDeleteConfirm => 'Eliminare questa conversazione?';

  @override
  String get chatRename => 'Rinomina';

  @override
  String get chatRenameTitle => 'Rinomina conversazione';

  @override
  String get chatStatusError => 'Impossibile verificare lo stato della chat';

  @override
  String get settingsChangeServer => 'Cambia server';

  @override
  String get settingsChangeServerConfirm =>
      'Cambiare server? Verrai disconnesso da quello attuale.';

  @override
  String errorWeakPasswordDetail(String requirements) {
    return 'La password deve includere: $requirements';
  }

  @override
  String get pwMinLength => 'una lunghezza maggiore';

  @override
  String get pwRequireLower => 'una lettera minuscola';

  @override
  String get pwRequireUpper => 'una lettera maiuscola';

  @override
  String get pwRequireDigit => 'una cifra';

  @override
  String get pwRequireSymbol => 'un simbolo';

  @override
  String get pwMinCharClasses => 'più tipi di carattere';

  @override
  String get updateAvailable =>
      'È disponibile una versione più recente dell\'app.';

  @override
  String get updateRequiredTitle => 'Aggiornamento necessario';

  @override
  String updateRequiredBody(String current) {
    return 'Questa versione dell\'app ($current) non è più supportata dal server. Aggiorna all\'ultima versione per continuare a usare Cerca posta.';
  }

  @override
  String get updateRequiredButton => 'Aggiorna ora';

  @override
  String get updateStoreError =>
      'Impossibile aprire lo store. Aggiorna manualmente dall\'App Store o dal Play Store.';

  @override
  String get emailPecSection => 'Busta di trasporto PEC';

  @override
  String get emailPecTransportFrom => 'Trasporto da';

  @override
  String get emailPecTransportSubject => 'Oggetto busta';

  @override
  String get emailPecTransportDate => 'Data trasporto';

  @override
  String get emailPecDaticert => 'Certificazione (daticert.xml) presente';

  @override
  String get settingsStorage => 'Spazio archivio';

  @override
  String settingsStorageValue(String used, String quota, String percent) {
    return '$used di $quota ($percent%)';
  }

  @override
  String settingsStorageUnlimited(String used) {
    return '$used · illimitato';
  }

  @override
  String get errorInvalidCredentials => 'Credenziali non valide';

  @override
  String get errorAccountBanned =>
      'Account temporaneamente bloccato per troppi tentativi';

  @override
  String get errorInvalidToken => 'Sessione scaduta, accedi di nuovo';

  @override
  String get errorInvalidRefresh => 'Sessione non valida, accedi di nuovo';

  @override
  String get errorForbidden => 'Operazione non consentita';

  @override
  String get errorAdminNotOnMobile =>
      'Le funzioni di amministrazione non sono disponibili da mobile';

  @override
  String get errorTotpInvalidCode => 'Codice non valido';

  @override
  String get errorTotpExpired => 'Codice scaduto, accedi di nuovo';

  @override
  String get errorDekLocked => 'Archivio bloccato. Sblocca con la password.';

  @override
  String get errorRecoveryFailed =>
      'Recupero fallito. Verifica il codice di recupero.';

  @override
  String get errorWeakPassword =>
      'La password non rispetta i requisiti di sicurezza';

  @override
  String get errorTotpSetupRequired =>
      'Il tuo account richiede la verifica in due passaggi: configurala dal web prima di accedere dall\'app';

  @override
  String get errorChatNotConfigured => 'Chat AI non configurata';

  @override
  String errorChatLlmError(String detail) {
    return 'Errore del modello AI: $detail';
  }

  @override
  String get errorNotFound => 'Elemento non trovato';

  @override
  String get errorPreviewUnsupported =>
      'Anteprima non disponibile per questo formato';

  @override
  String get errorPreviewFailed => 'Impossibile generare l\'anteprima';

  @override
  String get errorRawMissing => 'File non più disponibile';

  @override
  String get errorValidation => 'Dati non validi';

  @override
  String get errorNetwork => 'Errore di rete. Verifica la connessione.';

  @override
  String get errorGeneric => 'Errore imprevisto';
}
