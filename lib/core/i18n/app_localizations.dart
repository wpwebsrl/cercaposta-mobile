import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'i18n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appName.
  ///
  /// In it, this message translates to:
  /// **'Cerca posta'**
  String get appName;

  /// No description provided for @actionCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get actionCancel;

  /// No description provided for @actionConfirm.
  ///
  /// In it, this message translates to:
  /// **'Conferma'**
  String get actionConfirm;

  /// No description provided for @actionClose.
  ///
  /// In it, this message translates to:
  /// **'Chiudi'**
  String get actionClose;

  /// No description provided for @actionRetry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get actionRetry;

  /// No description provided for @actionSave.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get actionSave;

  /// No description provided for @actionApply.
  ///
  /// In it, this message translates to:
  /// **'Applica'**
  String get actionApply;

  /// No description provided for @actionClear.
  ///
  /// In it, this message translates to:
  /// **'Pulisci'**
  String get actionClear;

  /// No description provided for @actionContinue.
  ///
  /// In it, this message translates to:
  /// **'Continua'**
  String get actionContinue;

  /// No description provided for @actionRemove.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi'**
  String get actionRemove;

  /// No description provided for @actionOpenInBrowser.
  ///
  /// In it, this message translates to:
  /// **'Apri nel browser'**
  String get actionOpenInBrowser;

  /// No description provided for @loading.
  ///
  /// In it, this message translates to:
  /// **'Caricamento…'**
  String get loading;

  /// No description provided for @today.
  ///
  /// In it, this message translates to:
  /// **'Oggi'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In it, this message translates to:
  /// **'Ieri'**
  String get yesterday;

  /// No description provided for @serverTitle.
  ///
  /// In it, this message translates to:
  /// **'Scegli il server'**
  String get serverTitle;

  /// No description provided for @serverSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Inserisci l\'indirizzo del tuo server Cerca posta.'**
  String get serverSubtitle;

  /// No description provided for @serverUrlLabel.
  ///
  /// In it, this message translates to:
  /// **'Indirizzo server'**
  String get serverUrlLabel;

  /// No description provided for @serverUrlHint.
  ///
  /// In it, this message translates to:
  /// **'https://mail.esempio.it'**
  String get serverUrlHint;

  /// No description provided for @serverValidating.
  ///
  /// In it, this message translates to:
  /// **'Validazione del server…'**
  String get serverValidating;

  /// No description provided for @serverInvalid.
  ///
  /// In it, this message translates to:
  /// **'Indirizzo non valido o server non raggiungibile'**
  String get serverInvalid;

  /// No description provided for @serverNotCercaPosta.
  ///
  /// In it, this message translates to:
  /// **'Questo server non è un\'istanza Cerca posta'**
  String get serverNotCercaPosta;

  /// No description provided for @serverSavedTitle.
  ///
  /// In it, this message translates to:
  /// **'Server salvati'**
  String get serverSavedTitle;

  /// No description provided for @serverNeedsSetup.
  ///
  /// In it, this message translates to:
  /// **'Questo server va ancora configurato dal web.'**
  String get serverNeedsSetup;

  /// No description provided for @serverUpdateRequired.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna l\'app per usare questo server.'**
  String get serverUpdateRequired;

  /// No description provided for @loginTitle.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get loginTitle;

  /// No description provided for @loginUsername.
  ///
  /// In it, this message translates to:
  /// **'Nome utente'**
  String get loginUsername;

  /// No description provided for @loginPassword.
  ///
  /// In it, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginButton.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get loginButton;

  /// No description provided for @loginChangeServer.
  ///
  /// In it, this message translates to:
  /// **'Cambia server'**
  String get loginChangeServer;

  /// No description provided for @loginBiometric.
  ///
  /// In it, this message translates to:
  /// **'Accedi con la biometria'**
  String get loginBiometric;

  /// No description provided for @loginBiometricReason.
  ///
  /// In it, this message translates to:
  /// **'Accedi al tuo archivio email'**
  String get loginBiometricReason;

  /// No description provided for @loginEnableBiometricTitle.
  ///
  /// In it, this message translates to:
  /// **'Accesso rapido'**
  String get loginEnableBiometricTitle;

  /// No description provided for @loginEnableBiometricBody.
  ///
  /// In it, this message translates to:
  /// **'Vuoi accedere con Face ID / impronta la prossima volta? Le credenziali vengono salvate in modo sicuro sul dispositivo.'**
  String get loginEnableBiometricBody;

  /// No description provided for @sharedFromLabel.
  ///
  /// In it, this message translates to:
  /// **'da {name}'**
  String sharedFromLabel(String name);

  /// No description provided for @sharedReaderBanner.
  ///
  /// In it, this message translates to:
  /// **'Cartella condivisa da {name} — sola lettura'**
  String sharedReaderBanner(String name);

  /// No description provided for @totpTitle.
  ///
  /// In it, this message translates to:
  /// **'Verifica in due passaggi'**
  String get totpTitle;

  /// No description provided for @totpSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il codice dell\'app di autenticazione.'**
  String get totpSubtitle;

  /// No description provided for @totpCode.
  ///
  /// In it, this message translates to:
  /// **'Codice a 6 cifre'**
  String get totpCode;

  /// No description provided for @totpButton.
  ///
  /// In it, this message translates to:
  /// **'Verifica'**
  String get totpButton;

  /// No description provided for @unlockTitle.
  ///
  /// In it, this message translates to:
  /// **'Sblocca archivio'**
  String get unlockTitle;

  /// No description provided for @unlockDescription.
  ///
  /// In it, this message translates to:
  /// **'Il tuo archivio è cifrato. Inserisci la password per accedere ai contenuti.'**
  String get unlockDescription;

  /// No description provided for @unlockPassword.
  ///
  /// In it, this message translates to:
  /// **'Password'**
  String get unlockPassword;

  /// No description provided for @unlockButton.
  ///
  /// In it, this message translates to:
  /// **'Sblocca'**
  String get unlockButton;

  /// No description provided for @unlockBiometric.
  ///
  /// In it, this message translates to:
  /// **'Sblocca con la biometria'**
  String get unlockBiometric;

  /// No description provided for @unlockEnableBiometricTitle.
  ///
  /// In it, this message translates to:
  /// **'Sblocco rapido'**
  String get unlockEnableBiometricTitle;

  /// No description provided for @unlockEnableBiometricBody.
  ///
  /// In it, this message translates to:
  /// **'Vuoi sbloccare l\'archivio con la biometria ai prossimi avvii? La password viene salvata in modo sicuro sul dispositivo.'**
  String get unlockEnableBiometricBody;

  /// No description provided for @unlockEnableBiometricYes.
  ///
  /// In it, this message translates to:
  /// **'Sì, abilita'**
  String get unlockEnableBiometricYes;

  /// No description provided for @unlockEnableBiometricNo.
  ///
  /// In it, this message translates to:
  /// **'No, grazie'**
  String get unlockEnableBiometricNo;

  /// No description provided for @unlockReason.
  ///
  /// In it, this message translates to:
  /// **'Sblocca il tuo archivio cifrato'**
  String get unlockReason;

  /// No description provided for @firstPasswordTitle.
  ///
  /// In it, this message translates to:
  /// **'Imposta nuova password'**
  String get firstPasswordTitle;

  /// No description provided for @firstPasswordSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Al primo accesso devi scegliere una password personale (l\'amministratore non la conoscerà).'**
  String get firstPasswordSubtitle;

  /// No description provided for @firstPasswordNew.
  ///
  /// In it, this message translates to:
  /// **'Nuova password'**
  String get firstPasswordNew;

  /// No description provided for @firstPasswordConfirm.
  ///
  /// In it, this message translates to:
  /// **'Conferma password'**
  String get firstPasswordConfirm;

  /// No description provided for @firstPasswordMismatch.
  ///
  /// In it, this message translates to:
  /// **'Le password non coincidono'**
  String get firstPasswordMismatch;

  /// No description provided for @kitTitle.
  ///
  /// In it, this message translates to:
  /// **'Kit di emergenza'**
  String get kitTitle;

  /// No description provided for @kitBody.
  ///
  /// In it, this message translates to:
  /// **'Conserva questo codice in un luogo sicuro: serve a recuperare l\'archivio se dimentichi la password. Viene mostrato SOLO ora.'**
  String get kitBody;

  /// No description provided for @kitCopy.
  ///
  /// In it, this message translates to:
  /// **'Copia'**
  String get kitCopy;

  /// No description provided for @kitCopied.
  ///
  /// In it, this message translates to:
  /// **'Copiato negli appunti'**
  String get kitCopied;

  /// No description provided for @recoveryTitle.
  ///
  /// In it, this message translates to:
  /// **'Recupero archivio'**
  String get recoveryTitle;

  /// No description provided for @recoverySubtitle.
  ///
  /// In it, this message translates to:
  /// **'La password è stata reimpostata dall\'amministratore. Inserisci il codice del kit di emergenza e scegli una nuova password.'**
  String get recoverySubtitle;

  /// No description provided for @recoverySecretLabel.
  ///
  /// In it, this message translates to:
  /// **'Codice di recupero'**
  String get recoverySecretLabel;

  /// No description provided for @navSearch.
  ///
  /// In it, this message translates to:
  /// **'Cerca'**
  String get navSearch;

  /// No description provided for @navChat.
  ///
  /// In it, this message translates to:
  /// **'Chat AI'**
  String get navChat;

  /// No description provided for @navSettings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get navSettings;

  /// No description provided for @navNotifications.
  ///
  /// In it, this message translates to:
  /// **'Notifiche'**
  String get navNotifications;

  /// No description provided for @notificationsTitle.
  ///
  /// In it, this message translates to:
  /// **'Notifiche'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessuna notifica.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsDismiss.
  ///
  /// In it, this message translates to:
  /// **'Ignora'**
  String get notificationsDismiss;

  /// No description provided for @notifReprocessTitle.
  ///
  /// In it, this message translates to:
  /// **'Rielabora l\'archivio per adattarlo agli aggiornamenti'**
  String get notifReprocessTitle;

  /// No description provided for @notifReprocessBody.
  ///
  /// In it, this message translates to:
  /// **'Un aggiornamento dell\'app ha migliorato il modo in cui vengono gestite le email già in archivio (ad esempio le immagini incorporate nelle firme non contano più come allegati). La rielaborazione dell\'archivio si avvia dall\'app web.'**
  String get notifReprocessBody;

  /// No description provided for @searchHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca… (da:, tag:, ha:pdf…)'**
  String get searchHint;

  /// No description provided for @searchVoice.
  ///
  /// In it, this message translates to:
  /// **'Ricerca vocale'**
  String get searchVoice;

  /// No description provided for @searchVoiceListening.
  ///
  /// In it, this message translates to:
  /// **'In ascolto…'**
  String get searchVoiceListening;

  /// No description provided for @searchVoiceUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Riconoscimento vocale non disponibile'**
  String get searchVoiceUnavailable;

  /// No description provided for @searchVoicePermission.
  ///
  /// In it, this message translates to:
  /// **'Permesso microfono negato'**
  String get searchVoicePermission;

  /// No description provided for @searchFilters.
  ///
  /// In it, this message translates to:
  /// **'Filtri'**
  String get searchFilters;

  /// No description provided for @searchNoResults.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato'**
  String get searchNoResults;

  /// No description provided for @searchLoading.
  ///
  /// In it, this message translates to:
  /// **'Ricerca in corso…'**
  String get searchLoading;

  /// No description provided for @searchEmptyPrompt.
  ///
  /// In it, this message translates to:
  /// **'Cerca nel tuo archivio per parole chiave o con gli operatori.'**
  String get searchEmptyPrompt;

  /// No description provided for @searchResultsCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Nessun risultato} =1{1 risultato} other{{count} risultati}}'**
  String searchResultsCount(int count);

  /// No description provided for @attachmentsCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 allegato} other{{count} allegati}}'**
  String attachmentsCount(int count);

  /// No description provided for @filtersTitle.
  ///
  /// In it, this message translates to:
  /// **'Filtri'**
  String get filtersTitle;

  /// No description provided for @filterFrom.
  ///
  /// In it, this message translates to:
  /// **'Da'**
  String get filterFrom;

  /// No description provided for @filterTo.
  ///
  /// In it, this message translates to:
  /// **'A / CC'**
  String get filterTo;

  /// No description provided for @filterSubject.
  ///
  /// In it, this message translates to:
  /// **'Oggetto'**
  String get filterSubject;

  /// No description provided for @filterHasAttachments.
  ///
  /// In it, this message translates to:
  /// **'Con allegati'**
  String get filterHasAttachments;

  /// No description provided for @filterAttachmentExt.
  ///
  /// In it, this message translates to:
  /// **'Tipo allegato (es. pdf)'**
  String get filterAttachmentExt;

  /// No description provided for @filterDateFrom.
  ///
  /// In it, this message translates to:
  /// **'Dopo il'**
  String get filterDateFrom;

  /// No description provided for @filterDateTo.
  ///
  /// In it, this message translates to:
  /// **'Prima del'**
  String get filterDateTo;

  /// No description provided for @filterTags.
  ///
  /// In it, this message translates to:
  /// **'Tag'**
  String get filterTags;

  /// No description provided for @filterFolders.
  ///
  /// In it, this message translates to:
  /// **'Cartelle'**
  String get filterFolders;

  /// No description provided for @foldersTitle.
  ///
  /// In it, this message translates to:
  /// **'Cartelle'**
  String get foldersTitle;

  /// No description provided for @foldersAll.
  ///
  /// In it, this message translates to:
  /// **'Tutte le cartelle'**
  String get foldersAll;

  /// No description provided for @foldersRefresh.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna'**
  String get foldersRefresh;

  /// No description provided for @foldersEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessuna cartella nell\'archivio'**
  String get foldersEmpty;

  /// No description provided for @foldersExpand.
  ///
  /// In it, this message translates to:
  /// **'Espandi'**
  String get foldersExpand;

  /// No description provided for @foldersCollapse.
  ///
  /// In it, this message translates to:
  /// **'Comprimi'**
  String get foldersCollapse;

  /// No description provided for @foldersMultiple.
  ///
  /// In it, this message translates to:
  /// **'{count} cartelle'**
  String foldersMultiple(int count);

  /// No description provided for @aboutTitle.
  ///
  /// In it, this message translates to:
  /// **'Informazioni'**
  String get aboutTitle;

  /// No description provided for @aboutCompany.
  ///
  /// In it, this message translates to:
  /// **'WpWeb S.r.l.'**
  String get aboutCompany;

  /// No description provided for @aboutBuildLabel.
  ///
  /// In it, this message translates to:
  /// **'build'**
  String get aboutBuildLabel;

  /// No description provided for @aboutWebsite.
  ///
  /// In it, this message translates to:
  /// **'Visita wpweb.com'**
  String get aboutWebsite;

  /// No description provided for @aboutCredits.
  ///
  /// In it, this message translates to:
  /// **'Cerca posta è un prodotto WpWeb: archivio email intelligente, cifrato e ricercabile.\nTutte le tue email, finalmente in un unico posto.\nAnni di messaggi, conversazioni e allegati, raccolti e messi in ordine.\nNiente più caselle sparse, vecchi backup o file dimenticati.\nCerca posta riunisce tutto in un archivio sicuro, sempre a portata di mano.\nTrovare un\'email non è più una caccia al tesoro.\nScrivi quello che ricordi, come lo diresti a voce.\nUn nome, una data, una parola: i risultati arrivano in un istante.\nE se non ricordi le parole esatte? Nessun problema.\nCerca posta capisce il significato di ciò che cerchi, non solo le parole.\nCerchi «il preventivo dell\'idraulico dell\'anno scorso»?\nLo trova, anche se in quell\'email la parola «preventivo» non c\'era.\nC\'è anche un assistente intelligente che legge le email al posto tuo.\nFagli domande con parole tue e ricevi risposte chiare.\n«Quando ho confermato l\'appuntamento dal dentista?»\n«Qual è l\'IBAN che mi ha mandato il fornitore?»\nRisponde citando le email giuste, così puoi sempre verificare di persona.\nAnche gli allegati diventano cercabili.\nPDF, documenti, fogli di calcolo e persino il testo dentro le immagini.\nQuella fattura, quel contratto, quella foto: a portata di ricerca.\nBasta ore passate a scorrere la posta in cerca di un dettaglio.\nFiltra per cartella, per etichetta, per mittente o per periodo.\nRestringi la ricerca con pochi clic e vai dritto al punto.\nOgni messaggio si apre pulito e ben leggibile.\nE la cosa più importante: i tuoi dati restano tuoi, e solo tuoi.\nTutto è cifrato a riposo con la tua chiave personale.\nUn database o un backup rubati restano illeggibili.\nLa chiave di sicurezza è soltanto tua.\nCerca posta è un archivio in sola lettura.\nNon invia, non risponde e non modifica nulla nelle caselle di origine.\nConserva e protegge, senza mai toccare la fonte.\nÈ pensato per chi ha tante email e poco tempo.\nProfessionisti, aziende, studi, uffici e amministrazioni.\nÈ semplice da usare per chiunque.\nNessun manuale, nessuna complicazione.\nApri, scrivi cosa cerchi, trova. Tutto qui.\nLa memoria della tua corrispondenza, sempre con te.\nQuello che ti serve, esattamente quando ti serve.\nRitrova in pochi secondi ciò che credevi perso per sempre.\nRecupera informazioni, accordi e decisioni prese via email.\nTrasforma anni di posta in una risorsa viva e consultabile.\nPiù ordine, meno stress.\nPiù tempo per ciò che conta davvero.\nVeloce quando cerchi, discreto quando custodisce.\nAffidabile ogni volta che ti serve.\nSicuro per progettazione, semplice per scelta.\nIl tuo archivio email, intelligente e protetto.\nCercabile in tutto, comprensibile da subito.\nCerca posta: ritrova tutto, non perdere niente.\nUn prodotto WpWeb.\nTecnologia che semplifica la vita digitale.\nGrazie per aver scelto Cerca posta.'**
  String get aboutCredits;

  /// No description provided for @emailLoading.
  ///
  /// In it, this message translates to:
  /// **'Caricamento messaggio…'**
  String get emailLoading;

  /// No description provided for @emailNoBody.
  ///
  /// In it, this message translates to:
  /// **'Nessun contenuto da mostrare.'**
  String get emailNoBody;

  /// No description provided for @emailRawMissing.
  ///
  /// In it, this message translates to:
  /// **'Il messaggio originale non è più disponibile: vengono mostrati solo i metadati.'**
  String get emailRawMissing;

  /// No description provided for @emailAttachments.
  ///
  /// In it, this message translates to:
  /// **'Allegati'**
  String get emailAttachments;

  /// No description provided for @emailThread.
  ///
  /// In it, this message translates to:
  /// **'Conversazione'**
  String get emailThread;

  /// No description provided for @emailOpenAttachment.
  ///
  /// In it, this message translates to:
  /// **'Apri allegato'**
  String get emailOpenAttachment;

  /// No description provided for @emailShowRemoteImages.
  ///
  /// In it, this message translates to:
  /// **'Mostra immagini remote'**
  String get emailShowRemoteImages;

  /// No description provided for @emailPecBadge.
  ///
  /// In it, this message translates to:
  /// **'PEC'**
  String get emailPecBadge;

  /// No description provided for @emailTo.
  ///
  /// In it, this message translates to:
  /// **'A'**
  String get emailTo;

  /// No description provided for @emailCc.
  ///
  /// In it, this message translates to:
  /// **'CC'**
  String get emailCc;

  /// No description provided for @emailDate.
  ///
  /// In it, this message translates to:
  /// **'Data'**
  String get emailDate;

  /// No description provided for @attachmentLoading.
  ///
  /// In it, this message translates to:
  /// **'Caricamento anteprima…'**
  String get attachmentLoading;

  /// No description provided for @attachmentUnsupported.
  ///
  /// In it, this message translates to:
  /// **'Anteprima non disponibile per questo tipo di file.'**
  String get attachmentUnsupported;

  /// No description provided for @chatTitle.
  ///
  /// In it, this message translates to:
  /// **'Chat AI'**
  String get chatTitle;

  /// No description provided for @chatHint.
  ///
  /// In it, this message translates to:
  /// **'Fai una domanda sull\'archivio…'**
  String get chatHint;

  /// No description provided for @chatSend.
  ///
  /// In it, this message translates to:
  /// **'Invia'**
  String get chatSend;

  /// No description provided for @chatNotConfigured.
  ///
  /// In it, this message translates to:
  /// **'La chat AI non è configurata su questo server.'**
  String get chatNotConfigured;

  /// No description provided for @chatDisabled.
  ///
  /// In it, this message translates to:
  /// **'La chat AI è disattivata su questo server.'**
  String get chatDisabled;

  /// No description provided for @chatNew.
  ///
  /// In it, this message translates to:
  /// **'Nuova conversazione'**
  String get chatNew;

  /// No description provided for @chatHistory.
  ///
  /// In it, this message translates to:
  /// **'Cronologia'**
  String get chatHistory;

  /// No description provided for @chatHistoryEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessuna conversazione salvata.'**
  String get chatHistoryEmpty;

  /// No description provided for @chatCitations.
  ///
  /// In it, this message translates to:
  /// **'Fonti'**
  String get chatCitations;

  /// No description provided for @chatPhaseUnderstanding.
  ///
  /// In it, this message translates to:
  /// **'Comprensione…'**
  String get chatPhaseUnderstanding;

  /// No description provided for @chatPhaseSearching.
  ///
  /// In it, this message translates to:
  /// **'Ricerca…'**
  String get chatPhaseSearching;

  /// No description provided for @chatPhaseEmbedding.
  ///
  /// In it, this message translates to:
  /// **'Analisi semantica…'**
  String get chatPhaseEmbedding;

  /// No description provided for @chatPhaseReranking.
  ///
  /// In it, this message translates to:
  /// **'Riordino…'**
  String get chatPhaseReranking;

  /// No description provided for @chatPhaseGenerating.
  ///
  /// In it, this message translates to:
  /// **'Generazione risposta…'**
  String get chatPhaseGenerating;

  /// No description provided for @chatEmbeddingFailed.
  ///
  /// In it, this message translates to:
  /// **'Ricerca semantica non disponibile: risultati basati sulle sole parole chiave.'**
  String get chatEmbeddingFailed;

  /// No description provided for @settingsTitle.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settingsTitle;

  /// No description provided for @settingsServer.
  ///
  /// In it, this message translates to:
  /// **'Server'**
  String get settingsServer;

  /// No description provided for @settingsAccount.
  ///
  /// In it, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsLanguage.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageIt.
  ///
  /// In it, this message translates to:
  /// **'Italiano'**
  String get settingsLanguageIt;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In it, this message translates to:
  /// **'Inglese'**
  String get settingsLanguageEn;

  /// No description provided for @settingsTheme.
  ///
  /// In it, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In it, this message translates to:
  /// **'Chiaro'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In it, this message translates to:
  /// **'Scuro'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeAuto.
  ///
  /// In it, this message translates to:
  /// **'Automatico'**
  String get settingsThemeAuto;

  /// No description provided for @settingsBiometric.
  ///
  /// In it, this message translates to:
  /// **'Accesso e sblocco con biometria'**
  String get settingsBiometric;

  /// No description provided for @settingsBiometricEnablePrompt.
  ///
  /// In it, this message translates to:
  /// **'Inserisci la password del tuo account per abilitare l\'accesso e lo sblocco con la biometria.'**
  String get settingsBiometricEnablePrompt;

  /// No description provided for @settingsSessions.
  ///
  /// In it, this message translates to:
  /// **'Dispositivi e sessioni'**
  String get settingsSessions;

  /// No description provided for @settingsLogout.
  ///
  /// In it, this message translates to:
  /// **'Esci'**
  String get settingsLogout;

  /// No description provided for @settingsAbout.
  ///
  /// In it, this message translates to:
  /// **'Informazioni'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In it, this message translates to:
  /// **'Versione {version}'**
  String settingsVersion(String version);

  /// No description provided for @sessionsTitle.
  ///
  /// In it, this message translates to:
  /// **'Dispositivi e sessioni'**
  String get sessionsTitle;

  /// No description provided for @sessionsCurrent.
  ///
  /// In it, this message translates to:
  /// **'Questo dispositivo'**
  String get sessionsCurrent;

  /// No description provided for @sessionsRevoke.
  ///
  /// In it, this message translates to:
  /// **'Disconnetti'**
  String get sessionsRevoke;

  /// No description provided for @sessionsRevokeAll.
  ///
  /// In it, this message translates to:
  /// **'Disconnetti tutti'**
  String get sessionsRevokeAll;

  /// No description provided for @sessionsRevokeAllConfirm.
  ///
  /// In it, this message translates to:
  /// **'Disconnettere tutti i dispositivi? Dovrai accedere di nuovo su ognuno.'**
  String get sessionsRevokeAllConfirm;

  /// No description provided for @sessionsEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessuna sessione attiva.'**
  String get sessionsEmpty;

  /// No description provided for @sessionsLastSeen.
  ///
  /// In it, this message translates to:
  /// **'Ultimo accesso: {when}'**
  String sessionsLastSeen(String when);

  /// No description provided for @sessionsCreated.
  ///
  /// In it, this message translates to:
  /// **'Attiva dal: {when}'**
  String sessionsCreated(String when);

  /// No description provided for @sessionsIp.
  ///
  /// In it, this message translates to:
  /// **'Indirizzo IP: {ip}'**
  String sessionsIp(String ip);

  /// No description provided for @serverHttpsRequired.
  ///
  /// In it, this message translates to:
  /// **'Il server deve usare HTTPS. Gli indirizzi http:// non sono ammessi.'**
  String get serverHttpsRequired;

  /// No description provided for @serverRemoveSaved.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi dai server salvati'**
  String get serverRemoveSaved;

  /// No description provided for @searchClear.
  ///
  /// In it, this message translates to:
  /// **'Cancella la ricerca'**
  String get searchClear;

  /// No description provided for @searchLoadMoreError.
  ///
  /// In it, this message translates to:
  /// **'Errore di caricamento. Tocca per riprovare.'**
  String get searchLoadMoreError;

  /// No description provided for @filterSize.
  ///
  /// In it, this message translates to:
  /// **'Dimensione'**
  String get filterSize;

  /// No description provided for @filterSizeGreater.
  ///
  /// In it, this message translates to:
  /// **'maggiore di'**
  String get filterSizeGreater;

  /// No description provided for @filterSizeLess.
  ///
  /// In it, this message translates to:
  /// **'minore di'**
  String get filterSizeLess;

  /// No description provided for @filterAccount.
  ///
  /// In it, this message translates to:
  /// **'Account (ID sorgente)'**
  String get filterAccount;

  /// No description provided for @emailBcc.
  ///
  /// In it, this message translates to:
  /// **'CCN'**
  String get emailBcc;

  /// No description provided for @emailShareEml.
  ///
  /// In it, this message translates to:
  /// **'Condividi email (.eml)'**
  String get emailShareEml;

  /// No description provided for @emailLinkError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile aprire il link'**
  String get emailLinkError;

  /// No description provided for @attachmentShare.
  ///
  /// In it, this message translates to:
  /// **'Condividi'**
  String get attachmentShare;

  /// No description provided for @attachmentShareError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile condividere l\'allegato'**
  String get attachmentShareError;

  /// No description provided for @chatStop.
  ///
  /// In it, this message translates to:
  /// **'Interrompi'**
  String get chatStop;

  /// No description provided for @chatDelete.
  ///
  /// In it, this message translates to:
  /// **'Elimina conversazione'**
  String get chatDelete;

  /// No description provided for @chatDeleteConfirm.
  ///
  /// In it, this message translates to:
  /// **'Eliminare questa conversazione?'**
  String get chatDeleteConfirm;

  /// No description provided for @chatRename.
  ///
  /// In it, this message translates to:
  /// **'Rinomina'**
  String get chatRename;

  /// No description provided for @chatRenameTitle.
  ///
  /// In it, this message translates to:
  /// **'Rinomina conversazione'**
  String get chatRenameTitle;

  /// No description provided for @chatStatusError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile verificare lo stato della chat'**
  String get chatStatusError;

  /// No description provided for @settingsChangeServer.
  ///
  /// In it, this message translates to:
  /// **'Cambia server'**
  String get settingsChangeServer;

  /// No description provided for @settingsChangeServerConfirm.
  ///
  /// In it, this message translates to:
  /// **'Cambiare server? Verrai disconnesso da quello attuale.'**
  String get settingsChangeServerConfirm;

  /// No description provided for @errorWeakPasswordDetail.
  ///
  /// In it, this message translates to:
  /// **'La password deve includere: {requirements}'**
  String errorWeakPasswordDetail(String requirements);

  /// No description provided for @pwMinLength.
  ///
  /// In it, this message translates to:
  /// **'una lunghezza maggiore'**
  String get pwMinLength;

  /// No description provided for @pwRequireLower.
  ///
  /// In it, this message translates to:
  /// **'una lettera minuscola'**
  String get pwRequireLower;

  /// No description provided for @pwRequireUpper.
  ///
  /// In it, this message translates to:
  /// **'una lettera maiuscola'**
  String get pwRequireUpper;

  /// No description provided for @pwRequireDigit.
  ///
  /// In it, this message translates to:
  /// **'una cifra'**
  String get pwRequireDigit;

  /// No description provided for @pwRequireSymbol.
  ///
  /// In it, this message translates to:
  /// **'un simbolo'**
  String get pwRequireSymbol;

  /// No description provided for @pwMinCharClasses.
  ///
  /// In it, this message translates to:
  /// **'più tipi di carattere'**
  String get pwMinCharClasses;

  /// No description provided for @updateAvailable.
  ///
  /// In it, this message translates to:
  /// **'È disponibile una versione più recente dell\'app.'**
  String get updateAvailable;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamento necessario'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In it, this message translates to:
  /// **'Questa versione dell\'app ({current}) non è più supportata dal server. Aggiorna all\'ultima versione per continuare a usare Cerca posta.'**
  String updateRequiredBody(String current);

  /// No description provided for @updateRequiredButton.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna ora'**
  String get updateRequiredButton;

  /// No description provided for @updateStoreError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile aprire lo store. Aggiorna manualmente dall\'App Store o dal Play Store.'**
  String get updateStoreError;

  /// No description provided for @emailPecSection.
  ///
  /// In it, this message translates to:
  /// **'Busta di trasporto PEC'**
  String get emailPecSection;

  /// No description provided for @emailPecTransportFrom.
  ///
  /// In it, this message translates to:
  /// **'Trasporto da'**
  String get emailPecTransportFrom;

  /// No description provided for @emailPecTransportSubject.
  ///
  /// In it, this message translates to:
  /// **'Oggetto busta'**
  String get emailPecTransportSubject;

  /// No description provided for @emailPecTransportDate.
  ///
  /// In it, this message translates to:
  /// **'Data trasporto'**
  String get emailPecTransportDate;

  /// No description provided for @emailPecDaticert.
  ///
  /// In it, this message translates to:
  /// **'Certificazione (daticert.xml) presente'**
  String get emailPecDaticert;

  /// No description provided for @settingsStorage.
  ///
  /// In it, this message translates to:
  /// **'Spazio archivio'**
  String get settingsStorage;

  /// No description provided for @settingsStorageValue.
  ///
  /// In it, this message translates to:
  /// **'{used} di {quota} ({percent}%)'**
  String settingsStorageValue(String used, String quota, String percent);

  /// No description provided for @settingsStorageUnlimited.
  ///
  /// In it, this message translates to:
  /// **'{used} · illimitato'**
  String settingsStorageUnlimited(String used);

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In it, this message translates to:
  /// **'Credenziali non valide'**
  String get errorInvalidCredentials;

  /// No description provided for @errorAccountBanned.
  ///
  /// In it, this message translates to:
  /// **'Account temporaneamente bloccato per troppi tentativi'**
  String get errorAccountBanned;

  /// No description provided for @errorInvalidToken.
  ///
  /// In it, this message translates to:
  /// **'Sessione scaduta, accedi di nuovo'**
  String get errorInvalidToken;

  /// No description provided for @errorInvalidRefresh.
  ///
  /// In it, this message translates to:
  /// **'Sessione non valida, accedi di nuovo'**
  String get errorInvalidRefresh;

  /// No description provided for @errorForbidden.
  ///
  /// In it, this message translates to:
  /// **'Operazione non consentita'**
  String get errorForbidden;

  /// No description provided for @errorAdminNotOnMobile.
  ///
  /// In it, this message translates to:
  /// **'Le funzioni di amministrazione non sono disponibili da mobile'**
  String get errorAdminNotOnMobile;

  /// No description provided for @errorTotpInvalidCode.
  ///
  /// In it, this message translates to:
  /// **'Codice non valido'**
  String get errorTotpInvalidCode;

  /// No description provided for @errorTotpExpired.
  ///
  /// In it, this message translates to:
  /// **'Codice scaduto, accedi di nuovo'**
  String get errorTotpExpired;

  /// No description provided for @errorDekLocked.
  ///
  /// In it, this message translates to:
  /// **'Archivio bloccato. Sblocca con la password.'**
  String get errorDekLocked;

  /// No description provided for @errorRecoveryFailed.
  ///
  /// In it, this message translates to:
  /// **'Recupero fallito. Verifica il codice di recupero.'**
  String get errorRecoveryFailed;

  /// No description provided for @errorWeakPassword.
  ///
  /// In it, this message translates to:
  /// **'La password non rispetta i requisiti di sicurezza'**
  String get errorWeakPassword;

  /// No description provided for @errorTotpSetupRequired.
  ///
  /// In it, this message translates to:
  /// **'Il tuo account richiede la verifica in due passaggi: configurala dal web prima di accedere dall\'app'**
  String get errorTotpSetupRequired;

  /// No description provided for @errorChatNotConfigured.
  ///
  /// In it, this message translates to:
  /// **'Chat AI non configurata'**
  String get errorChatNotConfigured;

  /// No description provided for @errorChatLlmError.
  ///
  /// In it, this message translates to:
  /// **'Errore del modello AI: {detail}'**
  String errorChatLlmError(String detail);

  /// No description provided for @errorNotFound.
  ///
  /// In it, this message translates to:
  /// **'Elemento non trovato'**
  String get errorNotFound;

  /// No description provided for @errorPreviewUnsupported.
  ///
  /// In it, this message translates to:
  /// **'Anteprima non disponibile per questo formato'**
  String get errorPreviewUnsupported;

  /// No description provided for @errorPreviewFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile generare l\'anteprima'**
  String get errorPreviewFailed;

  /// No description provided for @errorRawMissing.
  ///
  /// In it, this message translates to:
  /// **'File non più disponibile'**
  String get errorRawMissing;

  /// No description provided for @errorValidation.
  ///
  /// In it, this message translates to:
  /// **'Dati non validi'**
  String get errorValidation;

  /// No description provided for @errorNetwork.
  ///
  /// In it, this message translates to:
  /// **'Errore di rete. Verifica la connessione.'**
  String get errorNetwork;

  /// No description provided for @errorGeneric.
  ///
  /// In it, this message translates to:
  /// **'Errore imprevisto'**
  String get errorGeneric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
