// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Cerca posta';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionSave => 'Save';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionOpenInBrowser => 'Open in browser';

  @override
  String get loading => 'Loading…';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get serverTitle => 'Choose server';

  @override
  String get serverSubtitle => 'Enter the address of your CercaPosta server.';

  @override
  String get serverUrlLabel => 'Server address';

  @override
  String get serverUrlHint => 'https://mail.example.com';

  @override
  String get serverValidating => 'Validating server…';

  @override
  String get serverInvalid => 'Invalid address or server unreachable';

  @override
  String get serverNotCercaPosta => 'This server is not a CercaPosta instance';

  @override
  String get serverSavedTitle => 'Saved servers';

  @override
  String get serverNeedsSetup =>
      'This server still needs to be set up from the web.';

  @override
  String get serverUpdateRequired => 'Update the app to use this server.';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginUsername => 'Username';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get loginChangeServer => 'Change server';

  @override
  String get loginBiometric => 'Sign in with biometrics';

  @override
  String get loginBiometricReason => 'Access your email archive';

  @override
  String get loginEnableBiometricTitle => 'Quick sign-in';

  @override
  String get loginEnableBiometricBody =>
      'Sign in with Face ID / fingerprint next time? Your credentials are stored securely on the device.';

  @override
  String sharedFromLabel(String name) {
    return 'from $name';
  }

  @override
  String sharedReaderBanner(String name) {
    return 'Folder shared by $name — read-only';
  }

  @override
  String get totpTitle => 'Two-step verification';

  @override
  String get totpSubtitle => 'Enter the code from your authenticator app.';

  @override
  String get totpCode => '6-digit code';

  @override
  String get totpButton => 'Verify';

  @override
  String get unlockTitle => 'Unlock archive';

  @override
  String get unlockDescription =>
      'Your archive is encrypted. Enter your password to access its contents.';

  @override
  String get unlockPassword => 'Password';

  @override
  String get unlockButton => 'Unlock';

  @override
  String get unlockBiometric => 'Unlock with biometrics';

  @override
  String get unlockEnableBiometricTitle => 'Quick unlock';

  @override
  String get unlockEnableBiometricBody =>
      'Unlock the archive with biometrics next time? Your password is stored securely on the device.';

  @override
  String get unlockEnableBiometricYes => 'Yes, enable';

  @override
  String get unlockEnableBiometricNo => 'No, thanks';

  @override
  String get unlockReason => 'Unlock your encrypted archive';

  @override
  String get firstPasswordTitle => 'Set a new password';

  @override
  String get firstPasswordSubtitle =>
      'On first access you must choose a personal password (the admin will never know it).';

  @override
  String get firstPasswordNew => 'New password';

  @override
  String get firstPasswordConfirm => 'Confirm password';

  @override
  String get firstPasswordMismatch => 'Passwords do not match';

  @override
  String get kitTitle => 'Emergency kit';

  @override
  String get kitBody =>
      'Store this code somewhere safe: it recovers your archive if you forget your password. It is shown ONLY now.';

  @override
  String get kitCopy => 'Copy';

  @override
  String get kitCopied => 'Copied to clipboard';

  @override
  String get recoveryTitle => 'Archive recovery';

  @override
  String get recoverySubtitle =>
      'Your password was reset by the administrator. Enter your emergency kit code and choose a new password.';

  @override
  String get recoverySecretLabel => 'Recovery code';

  @override
  String get navSearch => 'Search';

  @override
  String get navChat => 'AI Chat';

  @override
  String get navSettings => 'Settings';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications.';

  @override
  String get notificationsDismiss => 'Dismiss';

  @override
  String get notifReprocessTitle =>
      'Reprocess your archive to match recent updates';

  @override
  String get notifReprocessBody =>
      'An app update improved how already-archived emails are handled (for example, images embedded in signatures no longer count as attachments). Reprocessing the archive is started from the web app.';

  @override
  String get searchHint => 'Search… (from:, tag:, has:pdf…)';

  @override
  String get searchVoice => 'Voice search';

  @override
  String get searchVoiceListening => 'Listening…';

  @override
  String get searchVoiceUnavailable => 'Speech recognition unavailable';

  @override
  String get searchVoicePermission => 'Microphone permission denied';

  @override
  String get searchFilters => 'Filters';

  @override
  String get searchNoResults => 'No results';

  @override
  String get searchNewResults => 'New results';

  @override
  String get sortTooltip => 'Sort results';

  @override
  String get sortRelevance => 'Relevance';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get searchLoading => 'Searching…';

  @override
  String get searchEmptyPrompt =>
      'Search your archive by keywords or with operators.';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String attachmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments',
      one: '1 attachment',
    );
    return '$_temp0';
  }

  @override
  String get filtersTitle => 'Filters';

  @override
  String get filterFrom => 'From';

  @override
  String get filterTo => 'To / CC';

  @override
  String get filterSubject => 'Subject';

  @override
  String get filterHasAttachments => 'Has attachments';

  @override
  String get filterAttachmentExt => 'Attachment type (e.g. pdf)';

  @override
  String get filterDateFrom => 'After';

  @override
  String get filterDateTo => 'Before';

  @override
  String get filterTags => 'Tags';

  @override
  String get filterFolders => 'Folders';

  @override
  String get foldersTitle => 'Folders';

  @override
  String get foldersAll => 'All folders';

  @override
  String get foldersRefresh => 'Refresh';

  @override
  String get foldersEmpty => 'No folders in the archive';

  @override
  String get foldersExpand => 'Expand';

  @override
  String get foldersCollapse => 'Collapse';

  @override
  String foldersMultiple(int count) {
    return '$count folders';
  }

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutCompany => 'WpWeb S.r.l.';

  @override
  String get aboutBuildLabel => 'build';

  @override
  String get aboutWebsite => 'Visit wpweb.com';

  @override
  String get aboutCredits =>
      'Cerca posta is a WpWeb product: a smart, encrypted, searchable email archive.\nAll your email, finally in one place.\nYears of messages, conversations and attachments, gathered and put in order.\nNo more scattered mailboxes, old backups or forgotten files.\nCerca posta brings it all into one secure archive, always within reach.\nFinding an email is no longer a treasure hunt.\nType what you remember, the way you\'d say it out loud.\nA name, a date, a word: results appear in an instant.\nDon\'t recall the exact words? No problem.\nCerca posta understands the meaning of your search, not just the words.\nLooking for “last year\'s plumber quote”?\nIt finds it, even if that email never used the word “quote”.\nThere\'s also a smart assistant that reads your email for you.\nAsk it questions in your own words and get clear answers.\n“When did I confirm the dentist appointment?”\n“What\'s the IBAN the supplier sent me?”\nIt answers by citing the right emails, so you can always check for yourself.\nAttachments become searchable too.\nPDFs, documents, spreadsheets and even the text inside images.\nThat invoice, that contract, that photo: just a search away.\nNo more hours spent scrolling your inbox for one detail.\nFilter by folder, by tag, by sender or by date.\nNarrow your search in a few clicks and get straight to the point.\nEvery message opens clean and easy to read.\nAnd most important of all: your data stays yours, and yours alone.\nEverything is encrypted at rest with your personal key.\nA stolen database or backup stays unreadable.\nThe security key is yours and yours only.\nCerca posta is a read-only archive.\nIt never sends, replies to, or changes anything in your original mailboxes.\nIt preserves and protects, without ever touching the source.\nIt\'s made for people with lots of email and little time.\nProfessionals, companies, firms, offices and institutions.\nSimple for anyone to use.\nNo manual, no fuss.\nOpen it, type what you\'re after, find it. That\'s all.\nThe memory of your correspondence, always with you.\nWhat you need, exactly when you need it.\nRecover in seconds what you thought was lost for good.\nRetrieve information, agreements and decisions made over email.\nTurn years of mail into a living, searchable resource.\nMore order, less stress.\nMore time for what truly matters.\nFast when you search, discreet when it keeps.\nReliable every time you need it.\nSecure by design, simple by choice.\nYour email archive, smart and protected.\nSearchable in everything, clear from the very start.\nCerca posta: find everything, lose nothing.\nA WpWeb product.\nTechnology that simplifies digital life.\nThank you for choosing Cerca posta.';

  @override
  String get emailLoading => 'Loading message…';

  @override
  String get emailNoBody => 'No content to display.';

  @override
  String get emailRawMissing =>
      'The original message is no longer available: only metadata is shown.';

  @override
  String get emailAttachments => 'Attachments';

  @override
  String get emailThread => 'Conversation';

  @override
  String get emailOpenAttachment => 'Open attachment';

  @override
  String get emailShowRemoteImages => 'Show remote images';

  @override
  String get emailPecBadge => 'PEC';

  @override
  String get emailTo => 'To';

  @override
  String get emailCc => 'CC';

  @override
  String get emailDate => 'Date';

  @override
  String get attachmentLoading => 'Loading preview…';

  @override
  String get attachmentUnsupported =>
      'Preview not available for this file type.';

  @override
  String get chatTitle => 'AI Chat';

  @override
  String get chatHint => 'Ask a question about your archive…';

  @override
  String get chatSend => 'Send';

  @override
  String get chatNotConfigured => 'AI chat is not configured on this server.';

  @override
  String get chatDisabled => 'AI chat is disabled on this server.';

  @override
  String get chatNew => 'New conversation';

  @override
  String get chatHistory => 'History';

  @override
  String get chatHistoryEmpty => 'No saved conversations.';

  @override
  String get chatCitations => 'Sources';

  @override
  String get chatPhaseUnderstanding => 'Understanding…';

  @override
  String get chatPhaseSearching => 'Searching…';

  @override
  String get chatPhaseEmbedding => 'Semantic analysis…';

  @override
  String get chatPhaseReranking => 'Reranking…';

  @override
  String get chatPhaseGenerating => 'Generating answer…';

  @override
  String get chatEmbeddingFailed =>
      'Semantic search unavailable: results are keyword-only.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageIt => 'Italian';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeAuto => 'Automatic';

  @override
  String get settingsBiometric => 'Biometric sign-in and unlock';

  @override
  String get settingsBiometricEnablePrompt =>
      'Enter your account password to enable biometric sign-in and unlock.';

  @override
  String get settingsSessions => 'Devices & sessions';

  @override
  String get settingsLogout => 'Sign out';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get sessionsTitle => 'Devices & sessions';

  @override
  String get sessionsCurrent => 'This device';

  @override
  String get sessionsRevoke => 'Disconnect';

  @override
  String get sessionsRevokeAll => 'Disconnect all';

  @override
  String get sessionsRevokeAllConfirm =>
      'Disconnect all devices? You will need to sign in again on each one.';

  @override
  String get sessionsEmpty => 'No active sessions.';

  @override
  String sessionsLastSeen(String when) {
    return 'Last seen: $when';
  }

  @override
  String sessionsCreated(String when) {
    return 'Active since: $when';
  }

  @override
  String sessionsIp(String ip) {
    return 'IP address: $ip';
  }

  @override
  String get serverHttpsRequired =>
      'The server must use HTTPS. Plain http:// addresses are not allowed.';

  @override
  String get serverRemoveSaved => 'Remove from saved servers';

  @override
  String get searchClear => 'Clear search';

  @override
  String get searchLoadMoreError => 'Failed to load. Tap to retry.';

  @override
  String get filterSize => 'Size';

  @override
  String get filterSizeGreater => 'greater than';

  @override
  String get filterSizeLess => 'less than';

  @override
  String get filterAccount => 'Account (source ID)';

  @override
  String get emailBcc => 'BCC';

  @override
  String get emailShareEml => 'Share email (.eml)';

  @override
  String get emailLinkError => 'Could not open the link';

  @override
  String get attachmentShare => 'Share';

  @override
  String get attachmentShareError => 'Could not share the attachment';

  @override
  String get chatStop => 'Stop';

  @override
  String get chatDelete => 'Delete conversation';

  @override
  String get chatDeleteConfirm => 'Delete this conversation?';

  @override
  String get chatRename => 'Rename';

  @override
  String get chatRenameTitle => 'Rename conversation';

  @override
  String get chatStatusError => 'Could not check chat status';

  @override
  String get settingsChangeServer => 'Change server';

  @override
  String get settingsChangeServerConfirm =>
      'Change server? You\'ll be signed out of the current one.';

  @override
  String errorWeakPasswordDetail(String requirements) {
    return 'The password must include: $requirements';
  }

  @override
  String get pwMinLength => 'a greater length';

  @override
  String get pwRequireLower => 'a lowercase letter';

  @override
  String get pwRequireUpper => 'an uppercase letter';

  @override
  String get pwRequireDigit => 'a digit';

  @override
  String get pwRequireSymbol => 'a symbol';

  @override
  String get pwMinCharClasses => 'more character types';

  @override
  String get updateAvailable => 'A newer version of the app is available.';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String updateRequiredBody(String current) {
    return 'This app version ($current) is no longer supported by the server. Update to the latest version to keep using Cerca posta.';
  }

  @override
  String get updateRequiredButton => 'Update now';

  @override
  String get updateStoreError =>
      'Couldn\'t open the store. Update manually from the App Store or Play Store.';

  @override
  String get emailPecSection => 'PEC transport envelope';

  @override
  String get emailPecTransportFrom => 'Transported by';

  @override
  String get emailPecTransportSubject => 'Envelope subject';

  @override
  String get emailPecTransportDate => 'Transport date';

  @override
  String get emailPecDaticert => 'Certification (daticert.xml) present';

  @override
  String get settingsStorage => 'Storage';

  @override
  String settingsStorageValue(String used, String quota, String percent) {
    return '$used of $quota ($percent%)';
  }

  @override
  String settingsStorageUnlimited(String used) {
    return '$used · unlimited';
  }

  @override
  String get errorInvalidCredentials => 'Invalid credentials';

  @override
  String get errorAccountBanned =>
      'Account temporarily locked due to too many attempts';

  @override
  String get errorInvalidToken => 'Session expired, please sign in again';

  @override
  String get errorInvalidRefresh => 'Session invalid, please sign in again';

  @override
  String get errorForbidden => 'Operation not allowed';

  @override
  String get errorAdminNotOnMobile =>
      'Admin features are not available on mobile';

  @override
  String get errorTotpInvalidCode => 'Invalid code';

  @override
  String get errorTotpExpired => 'Code expired, please sign in again';

  @override
  String get errorDekLocked => 'Archive locked. Unlock with your password.';

  @override
  String get errorRecoveryFailed =>
      'Recovery failed. Check your recovery code.';

  @override
  String get errorWeakPassword =>
      'The password does not meet the security requirements';

  @override
  String get errorTotpSetupRequired =>
      'Your account requires two-step verification: set it up from the web before signing in from the app';

  @override
  String get errorChatNotConfigured => 'AI chat not configured';

  @override
  String errorChatLlmError(String detail) {
    return 'AI model error: $detail';
  }

  @override
  String get errorNotFound => 'Not found';

  @override
  String get errorPreviewUnsupported => 'Preview not available for this format';

  @override
  String get errorPreviewFailed => 'Could not generate the preview';

  @override
  String get errorRawMissing => 'File no longer available';

  @override
  String get errorValidation => 'Invalid data';

  @override
  String get errorNetwork => 'Network error. Check your connection.';

  @override
  String get errorGeneric => 'Unexpected error';
}
