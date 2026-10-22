// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get personalAiLabel => 'IA personnelle';

  @override
  String get managedAiLabel => 'IA de CercaPosta';

  @override
  String get errorPersonalAiUnavailable =>
      'L’IA personnelle est en pause : vérifiez votre offre, votre consentement et le déverrouillage de votre archive dans les paramètres Web.';

  @override
  String get errorSessionChanged =>
      'La session a changé. Réessayez avec le compte actuellement connecté.';

  @override
  String get appName => 'CercaPosta';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionConfirm => 'Confirmer';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionApply => 'Appliquer';

  @override
  String get actionClear => 'Effacer';

  @override
  String get actionContinue => 'Continuer';

  @override
  String get actionRemove => 'Retirer';

  @override
  String get actionOpenInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get loading => 'Chargement…';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get serverTitle => 'Choisir un serveur';

  @override
  String get serverSubtitle =>
      'Saisissez l\'adresse de votre serveur CercaPosta.';

  @override
  String get serverUrlLabel => 'Adresse du serveur';

  @override
  String get serverUrlHint => 'https://mail.example.com';

  @override
  String get serverValidating => 'Validation du serveur...';

  @override
  String get serverInvalid => 'Adresse ou serveur non accessible';

  @override
  String get serverNotCercaPosta =>
      'Ce serveur n\'est pas une instance CercaPosta';

  @override
  String get serverSavedTitle => 'Serveurs enregistrés';

  @override
  String get serverNeedsSetup =>
      'Ce serveur doit encore être configuré depuis l’interface Web.';

  @override
  String get serverUpdateRequired =>
      'Mettez à jour l’application pour utiliser ce serveur.';

  @override
  String get loginTitle => 'Se connecter';

  @override
  String get loginHeading => 'Se connecter à CercaPosta';

  @override
  String get loginTagline => 'Votre archive e-mail, interrogeable partout';

  @override
  String get loginUsername => 'Nom d’utilisateur';

  @override
  String get loginPassword => 'Mot de passe';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get loginPasskey => 'Se connecter avec une clé d’accès';

  @override
  String get loginGoogle => 'Continuer avec Google';

  @override
  String get loginApple => 'Se connecter avec Apple';

  @override
  String get loginChangeServer => 'Modifier le serveur';

  @override
  String get loginBiometric => 'Connexion avec biométrie';

  @override
  String get loginBiometricReason => 'Accédez à votre archive de courriels';

  @override
  String get loginEnableBiometricTitle => 'Accès rapide';

  @override
  String get loginEnableBiometricBody =>
      'Souhaitez-vous utiliser Face ID ou votre empreinte digitale la prochaine fois ? Cet appareil conservera une autorisation révocable protégée par la biométrie. L’application n’enregistrera pas le mot de passe de votre compte.';

  @override
  String sharedFromLabel(String name) {
    return 'de $name';
  }

  @override
  String sharedReaderBanner(String name) {
    return 'Dossier partagé par $name – en lecture seule';
  }

  @override
  String get totpTitle => 'Vérification en deux étapes';

  @override
  String get totpSubtitle =>
      'Saisissez le code de votre application d’authentification.';

  @override
  String get totpCode => 'Code à 6 chiffres';

  @override
  String get totpButton => 'Vérifier';

  @override
  String get unlockTitle => 'Déverrouiller l\'archive';

  @override
  String get unlockDescription =>
      'Votre archive est chiffrée. Saisissez votre mot de passe pour accéder à son contenu.';

  @override
  String get unlockPassword => 'Mot de passe';

  @override
  String get unlockButton => 'Déverrouiller';

  @override
  String get unlockBiometric => 'Déverrouiller par biométrie';

  @override
  String get unlockEnableBiometricTitle => 'Déverrouillage rapide';

  @override
  String get unlockEnableBiometricBody =>
      'Souhaitez-vous utiliser Face ID ou votre empreinte digitale pour déverrouiller l’archive ? Cet appareil conservera une autorisation révocable protégée par la biométrie.';

  @override
  String get unlockEnableBiometricYes => 'Oui, activer';

  @override
  String get unlockEnableBiometricNo => 'Non, merci.';

  @override
  String get unlockReason => 'Déverrouillez votre archive chiffrée';

  @override
  String get firstPasswordTitle => 'Définir un nouveau mot de passe';

  @override
  String get firstPasswordSubtitle =>
      'Lors du premier accès, vous devez choisir un mot de passe personnel (l\'administrateur ne le saura jamais).';

  @override
  String get firstPasswordNew => 'Nouveau mot de passe';

  @override
  String get firstPasswordConfirm => 'Confirmer le mot de passe';

  @override
  String get firstPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get kitTitle => 'Kit de récupération';

  @override
  String get kitBody =>
      'Conservez ce code en lieu sûr : il permet de récupérer votre archive si vous oubliez votre mot de passe. Il n’est affiché que MAINTENANT.';

  @override
  String get kitCopy => 'Copier';

  @override
  String get kitCopied => 'Copié au presse-papiers';

  @override
  String get recoveryTitle => 'Récupération d\'archives';

  @override
  String get recoverySubtitle =>
      'Votre mot de passe a été réinitialisé par l’administrateur. Saisissez le code de votre kit de récupération et choisissez un nouveau mot de passe.';

  @override
  String get recoverySecretLabel => 'Code de récupération';

  @override
  String get navSearch => 'Rechercher';

  @override
  String get navChat => 'Chat IA';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get navNotifications => 'Alertes';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'Pas de notification.';

  @override
  String get notificationsDismiss => 'Masquer';

  @override
  String get notificationsDismissAll => 'Tout effacer';

  @override
  String get notificationsDismissAllConfirm =>
      'Supprimer toutes les notifications ? Cette action est irréversible.';

  @override
  String get notifReprocessTitle =>
      'Retraitez votre archive pour appliquer les dernières améliorations';

  @override
  String get notifReprocessBody =>
      'Une mise à jour de l’application améliore le traitement des e-mails déjà archivés. Par exemple, les images intégrées dans les signatures ne sont plus comptées comme pièces jointes. Le retraitement de l’archive se lance depuis l’application Web.';

  @override
  String get searchHint => 'Rechercher… (from:, tag:, has:pdf…)';

  @override
  String get searchVoice => 'Recherche vocale';

  @override
  String get searchVoiceListening => 'Écoute en cours…';

  @override
  String get searchVoiceUnavailable => 'Reconnaissance vocale non disponible';

  @override
  String get searchVoicePermission =>
      'Autorisation d’accès au microphone refusée';

  @override
  String get searchFilters => 'Filtres';

  @override
  String get searchNoResults => 'Aucun résultat';

  @override
  String get searchNewResults => 'Nouveaux résultats';

  @override
  String get sortTooltip => 'Trier les résultats';

  @override
  String get sortRelevance => 'Pertinence';

  @override
  String get sortNewest => 'Plus récent';

  @override
  String get sortOldest => 'Les plus anciens';

  @override
  String get searchLoading => 'Recherche...';

  @override
  String get searchEmptyPrompt =>
      'Recherchez dans votre archive à l’aide de mots-clés ou d’opérateurs.';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
      zero: 'Aucun résultat',
    );
    return '$_temp0';
  }

  @override
  String attachmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièces jointes',
      one: '1 pièce jointe',
    );
    return '$_temp0';
  }

  @override
  String get filtersTitle => 'Filtres';

  @override
  String get filterFrom => 'De';

  @override
  String get filterTo => 'À / CC';

  @override
  String get filterSubject => 'Objet';

  @override
  String get filterHasAttachments => 'A des pièces jointes';

  @override
  String get filterAttachmentExt => 'Type de pièce jointe (par exemple pdf)';

  @override
  String get filterDateFrom => 'Après';

  @override
  String get filterDateTo => 'Avant';

  @override
  String get filterTags => 'Étiquettes';

  @override
  String get filterFolders => 'Dossiers';

  @override
  String get foldersTitle => 'Dossiers';

  @override
  String get foldersAll => 'Tous les dossiers';

  @override
  String get foldersRefresh => 'Actualiser';

  @override
  String get foldersEmpty => 'Aucun dossier dans l\'archive';

  @override
  String get foldersExpand => 'Développer';

  @override
  String get foldersCollapse => 'Réduire';

  @override
  String foldersMultiple(int count) {
    return '$count dossiers';
  }

  @override
  String get aboutTitle => 'À propos';

  @override
  String get aboutCompany => 'WpWeb S.r.l.';

  @override
  String get aboutBuildLabel => 'Build';

  @override
  String get aboutWebsite => 'Visitez wpweb.com';

  @override
  String get aboutCredits =>
      'CercaPosta est un produit WpWeb : une archive e-mail intelligente, chiffrée et interrogeable.\nTous vos e-mails, enfin au même endroit.\nDes années de messages, de conversations et de pièces jointes, rassemblés et organisés.\nFini les boîtes mail dispersées, les anciennes sauvegardes et les fichiers oubliés.\nCercaPosta rassemble tout dans une archive sécurisée, toujours à portée de main.\nRetrouver un e-mail n’est plus une chasse au trésor.\nSaisissez ce dont vous vous souvenez, comme vous le diriez à voix haute.\nUn nom, une date, un mot : les résultats apparaissent en un instant.\nVous ne vous rappelez pas les mots exacts ? Aucun problème.\nCercaPosta comprend le sens de votre recherche, pas seulement les mots.\nVous cherchez «le devis du plombier de l’année dernière» ?\nVous le retrouvez, même si cet e-mail ne contenait pas le mot «devis».\nUn assistant intelligent lit aussi vos e-mails pour vous.\nPosez vos questions avec vos propres mots et obtenez des réponses claires.\n«Quand ai-je confirmé le rendez-vous chez le dentiste ?»\n«Quel IBAN le fournisseur m’a-t-il envoyé ?»\nL’assistant cite les bons e-mails pour que vous puissiez toujours vérifier les réponses.\nLes pièces jointes deviennent elles aussi interrogeables.\nPDF, documents, feuilles de calcul et même le texte présent dans les images.\nCette facture, ce contrat, cette photo : une recherche suffit.\nPlus besoin de parcourir votre boîte de réception pendant des heures pour retrouver un détail.\nFiltrez par dossier, étiquette, expéditeur ou date.\nAffinez votre recherche en quelques clics et allez droit au but.\nChaque message s’ouvre dans une présentation claire et facile à lire.\nEt surtout : vos données restent les vôtres, et uniquement les vôtres.\nToutes les données stockées sont chiffrées avec votre clé personnelle.\nUne base de données ou une sauvegarde volée reste illisible.\nLa clé de sécurité vous appartient, à vous seul.\nCercaPosta est une archive en lecture seule.\nIl n’envoie aucun message, ne répond pas et ne modifie rien dans vos boîtes mail d’origine.\nIl conserve et protège sans jamais toucher à la source.\nIl s’adresse aux personnes qui ont beaucoup d’e-mails et peu de temps.\nProfessionnels, entreprises, cabinets, bureaux et institutions.\nSimple à utiliser pour tout le monde.\nSans manuel ni complication.\nOuvrez l’application, saisissez ce que vous cherchez et trouvez-le. C’est tout.\nLa mémoire de votre correspondance, toujours avec vous.\nCe dont vous avez besoin, au moment où vous en avez besoin.\nRetrouvez en quelques secondes ce que vous pensiez perdu pour toujours.\nRécupérez les informations, les accords et les décisions échangés par e-mail.\nTransformez des années de courrier en une ressource vivante et interrogeable.\nPlus d’ordre, moins de stress.\nPlus de temps pour ce qui compte vraiment.\nRapide dans la recherche, discret dans la conservation.\nFiable chaque fois que vous en avez besoin.\nSécurisé dès sa conception, simple par choix.\nVotre archive e-mail, intelligente et protégée.\nUne recherche dans tous les contenus, une interface claire dès le départ.\nCercaPosta : tout retrouver, ne rien perdre.\nUn produit WpWeb.\nUne technologie qui simplifie la vie numérique.\nMerci d’avoir choisi CercaPosta.';

  @override
  String get emailLoading => 'Chargement du message...';

  @override
  String get emailNoBody => 'Aucun contenu à afficher.';

  @override
  String get emailRawMissing =>
      'Le message original n\'est plus disponible : seules les métadonnées sont affichées.';

  @override
  String get emailAttachments => 'Pièces jointes';

  @override
  String get emailThread => 'Conversation';

  @override
  String get emailOpenAttachment => 'Ouvrir la pièce jointe';

  @override
  String get emailShowRemoteImages => 'Afficher les images distantes';

  @override
  String get emailAlwaysShowRemoteImagesFromSender =>
      'Toujours afficher les images de cet expéditeur';

  @override
  String get emailPecBadge => 'PEC';

  @override
  String get emailTo => 'À';

  @override
  String get emailCc => 'CC';

  @override
  String get emailDate => 'Date';

  @override
  String get emailFrom => 'De';

  @override
  String get emailDetails => 'Détails';

  @override
  String get emailThreadEmpty =>
      'Pas d\'autres messages dans cette conversation.';

  @override
  String get attachmentLoading => 'Chargement de l\'aperçu...';

  @override
  String get attachmentUnsupported =>
      'Aperçu non disponible pour ce type de fichier.';

  @override
  String get chatTitle => 'Chat IA';

  @override
  String get chatHint => 'Posez une question sur vos archives...';

  @override
  String get chatSend => 'Envoyer';

  @override
  String get chatNotConfigured =>
      'Le chat IA n’est pas configuré sur ce serveur.';

  @override
  String get chatDisabled => 'Le chat IA est désactivé sur ce serveur.';

  @override
  String get chatNew => 'Nouvelle conversation';

  @override
  String get chatHistory => 'Historique';

  @override
  String get chatHistoryEmpty => 'Pas de conversations enregistrées.';

  @override
  String get chatCitations => 'Sources';

  @override
  String get chatPhaseUnderstanding => 'Comprendre...';

  @override
  String get chatPhaseSearching => 'Recherche...';

  @override
  String get chatPhaseEmbedding => 'Analyse sémantique...';

  @override
  String get chatPhaseReranking => 'Reclassement...';

  @override
  String get chatPhaseGenerating => 'Générer une réponse...';

  @override
  String chatActivitySearch(String q) {
    return 'Recherche : « $q »';
  }

  @override
  String chatActivityThread(String s) {
    return 'Lecture de la conversation « $s »';
  }

  @override
  String get chatActivityThreadGeneric => 'Lecture d\'une conversation';

  @override
  String get chatActivityFollowups =>
      'Vérification des attentes en matière de réponse';

  @override
  String get chatActivityStats => 'Calcul des statistiques de l’archive';

  @override
  String chatActivityContact(String a) {
    return 'Collecte de l’historique de $a';
  }

  @override
  String chatActivityAttachments(String q) {
    return 'Lecture des pièces jointes : « $q »';
  }

  @override
  String get chatActivityAttachmentsGeneric => 'Lecture des pièces jointes';

  @override
  String chatCitationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count e-mails',
      one: '1 e-mail',
    );
    return '$_temp0';
  }

  @override
  String chatCitationsOthers(int count) {
    return 'et $count autres';
  }

  @override
  String chatCitationsShowAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Afficher les $count autres',
      one: 'Afficher le dernier',
    );
    return '$_temp0';
  }

  @override
  String get chatCitationsUnusedLegend =>
      'En grisé : e-mails lus mais non utilisés dans la réponse.';

  @override
  String chatPagingRead(int read, int total) {
    return '$read e-mails lus sur $total pour cette recherche.';
  }

  @override
  String chatPagingAll(int total) {
    return 'Les $total e-mails ont été lus pour cette recherche.';
  }

  @override
  String get chatEmbeddingFailed =>
      'Recherche sémantique indisponible : les résultats reposent uniquement sur les mots-clés.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLegalAndSupport => 'Informations légales et assistance';

  @override
  String get legalPrivacy => 'Politique de confidentialité';

  @override
  String get legalTerms => 'Conditions d\'utilisation';

  @override
  String get legalSupport => 'Assistance';

  @override
  String get legalSupportHint =>
      'Contacts, numéro de téléphone et moyens de demander de l\'aide';

  @override
  String get googleErrorCancelled => 'La connexion Google a été annulée';

  @override
  String get googleErrorState =>
      'La session Google n\'est plus valide : recommencer à s\'identifier';

  @override
  String get googleErrorConfiguration =>
      'La connexion Google n\'est pas configurée correctement sur le serveur';

  @override
  String get googleErrorIdentity =>
      'Google n\'a pas pu vérifier votre identité';

  @override
  String get googleErrorLinkRequired =>
      'Cette adresse existe déjà : associez Google depuis votre profil Web avant de l’utiliser ici.';

  @override
  String get googleErrorRegistrationRequired =>
      'Créez d\'abord le compte sur le site Web, puis connectez-vous à partir de cette application';

  @override
  String get googleErrorInactive => 'Le compte CercaPosta n\'est pas actif';

  @override
  String get googleErrorInvalid =>
      'La connexion Google est invalide ou expirée : réessayer';

  @override
  String get googleErrorDisabled =>
      'La connexion Google n\'est pas activée sur ce serveur';

  @override
  String get googleErrorUnavailable =>
      'La connexion Google n\'est pas disponible';

  @override
  String get appleErrorCancelled => 'La connexion Apple a été annulée';

  @override
  String get appleErrorState =>
      'La session Apple n\'est plus valide : recommencer à s\'identifier';

  @override
  String get appleErrorIdentity => 'Apple n\'a pas pu vérifier votre identité';

  @override
  String get appleErrorLinkRequired =>
      'Cette adresse existe déjà : associez Apple depuis votre profil Web avant de l’utiliser ici.';

  @override
  String get appleErrorRegistrationRequired =>
      'Créez d\'abord le compte sur le site Web, puis connectez-vous à partir de cette application';

  @override
  String get appleErrorInactive => 'Le compte CercaPosta n\'est pas actif';

  @override
  String get appleErrorInvalid =>
      'La connexion Apple est invalide ou expirée : réessayer';

  @override
  String get appleErrorDisabled =>
      'La connexion Apple n\'est pas activée sur ce serveur';

  @override
  String get appleErrorUnavailable =>
      'La connexion Apple n\'est pas disponible';

  @override
  String get settingsServer => 'Serveur';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Système';

  @override
  String get settingsLanguageIt => 'Italien';

  @override
  String get settingsLanguageEn => 'Anglais';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeAuto => 'Automatique';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsRemoteImages => 'Images dans l\'email';

  @override
  String get settingsRemoteImagesAlways =>
      'Afficher toujours les images distantes';

  @override
  String get settingsRemoteImagesWarning =>
      'Plus pratique, mais cela peut indiquer aux expéditeurs que vous avez ouvert un e-mail. Pour mieux protéger votre vie privée, n’autorisez que les expéditeurs de confiance.';

  @override
  String get settingsOsNotifications => 'Notifications système';

  @override
  String get settingsOsNotificationsHint =>
      'Affiche les nouvelles notifications dans le centre de notifications du téléphone. Sur Android, la vérification a lieu environ toutes les 15 minutes ; sur iOS, lorsque le système le permet.';

  @override
  String get settingsOsNotificationsDenied =>
      'Autorisation refusée : activez les notifications CercaPosta dans les paramètres du système.';

  @override
  String get settingsBiometric => 'Connexion et déverrouillage biométriques';

  @override
  String get settingsBiometricEnablePrompt =>
      'Confirmez votre mot de passe pour autoriser cet appareil, puis effectuez une vérification biométrique. L\'application ne conservera pas votre mot de passe.';

  @override
  String get settingsSessions => 'Appareils & sessions';

  @override
  String get passkeysTitle => 'Clés d’accès';

  @override
  String get passkeysSettingsHint =>
      'Connectez-vous sans taper votre mot de passe';

  @override
  String get passkeysDescription =>
      'Les clés d’accès utilisent le déverrouillage sécurisé de votre appareil, par exemple par empreinte digitale, reconnaissance faciale ou code PIN. La clé privée ne quitte jamais l’appareil ou votre fournisseur de clés d’accès.';

  @override
  String get passkeysAdd => 'Ajouter une clé d’accès';

  @override
  String get passkeysEmpty =>
      'Vous n’avez pas encore enregistré de clés d’accès.';

  @override
  String get passkeysSynced => 'Synchronisée';

  @override
  String get passkeysDeviceBound => 'Cet appareil uniquement';

  @override
  String passkeysCreated(String date) {
    return 'Créée le $date';
  }

  @override
  String passkeysLastUsed(String date) {
    return 'Dernière utilisation: $date';
  }

  @override
  String get passkeysRename => 'Renommer';

  @override
  String get passkeysRenameTitle => 'Renommer la clé d’accès';

  @override
  String get passkeysName => 'Nom de la clé d’accès';

  @override
  String get passkeysRemoveTitle => 'Supprimer la clé d’accès';

  @override
  String passkeysRemoveConfirm(String name) {
    return 'Supprimer la clé d’accès « $name » ? Vous ne pourrez plus l’utiliser pour vous connecter.';
  }

  @override
  String get passkeysPasswordStays =>
      'Les clés d’accès sont facultatives : le mot de passe et la connexion Google restent disponibles. Pour une archive chiffrée, un appareil nouveau ou non approuvé a toujours besoin du mot de passe ou du kit de récupération pour déverrouiller son contenu.';

  @override
  String get passkeyErrorCancelled => 'Opération annulée';

  @override
  String get passkeyErrorNoCredential =>
      'Aucune clé d’accès CercaPosta n’est disponible sur cet appareil';

  @override
  String get passkeyErrorDomainNotAssociated =>
      'Ce serveur n’est pas encore correctement associé à l’application pour les clés d’accès';

  @override
  String get passkeyErrorUnavailable =>
      'Les Passkeys ne sont pas disponibles sur cet appareil. Vous pouvez continuer à vous connecter avec votre mot de passe.';

  @override
  String get passkeyErrorTimeout =>
      'La demande de clé d’accès a expiré. Réessayez.';

  @override
  String get passkeyErrorInvalid =>
      'La clé d’accès n’a pas été reconnue ou n’est plus valide';

  @override
  String get passkeyErrorNotConfigured =>
      'Les clés d’accès ne sont pas encore configurées sur ce serveur';

  @override
  String get passkeyErrorAlreadyRegistered =>
      'Cette clé d’accès est déjà enregistrée';

  @override
  String get settingsLogout => 'Se déconnecter';

  @override
  String get settingsAbout => 'À propos';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get sessionsTitle => 'Appareils & sessions';

  @override
  String get sessionsCurrent => 'Cet appareil';

  @override
  String get sessionsRevoke => 'Se déconnecter';

  @override
  String get sessionsRevokeAll => 'Tout déconnecter';

  @override
  String get sessionsRevokeAllConfirm =>
      'Déconnecter tous les appareils ? Vous devrez vous connecter à nouveau sur chacun d\'eux.';

  @override
  String get sessionsEmpty => 'Aucune session active.';

  @override
  String sessionsLastSeen(String when) {
    return 'Dernière activité : $when';
  }

  @override
  String sessionsCreated(String when) {
    return 'Active depuis: $when';
  }

  @override
  String sessionsIp(String ip) {
    return 'Adresse IP : $ip';
  }

  @override
  String get serverHttpsRequired =>
      'Le serveur doit utiliser HTTPS. Les adresses simples http:// ne sont pas autorisées.';

  @override
  String get serverRemoveSaved => 'Supprimer des serveurs enregistrés';

  @override
  String get searchClear => 'Effacer la recherche';

  @override
  String get searchLoadMoreError =>
      'Échec du chargement. Appuyez pour réessayer.';

  @override
  String get filterSize => 'Taille';

  @override
  String get filterSizeGreater => 'supérieur à';

  @override
  String get filterSizeLess => 'inférieur à';

  @override
  String get filterAccount => 'Compte (ID source)';

  @override
  String get emailBcc => 'BCC';

  @override
  String get emailLinkError => 'Impossible d\'ouvrir le lien';

  @override
  String get attachmentShare => 'Partager';

  @override
  String get attachmentShareError => 'Impossible de partager la pièce jointe';

  @override
  String get chatStop => 'Arrêter';

  @override
  String get chatDelete => 'Supprimer la conversation';

  @override
  String get chatDeleteConfirm => 'Supprimer cette conversation ?';

  @override
  String get chatRename => 'Renommer';

  @override
  String get chatRenameTitle => 'Renommer la conversation';

  @override
  String get chatStatusError => 'Impossible de vérifier l\'état du chat';

  @override
  String get settingsChangeServer => 'Modifier le serveur';

  @override
  String get settingsChangeServerConfirm =>
      'Changer de serveur ? Vous serez déconnecté du serveur actuel.';

  @override
  String errorWeakPasswordDetail(String requirements) {
    return 'Le mot de passe doit comprendre : $requirements';
  }

  @override
  String get pwMinLength => 'une plus grande longueur';

  @override
  String get pwRequireLower => 'une lettre minuscule';

  @override
  String get pwRequireUpper => 'une lettre majuscule';

  @override
  String get pwRequireDigit => 'un chiffre';

  @override
  String get pwRequireSymbol => 'un symbole';

  @override
  String get pwMinCharClasses => 'plus de types de caractères';

  @override
  String get updateAvailable =>
      'Une version plus récente de l\'application est disponible.';

  @override
  String get updateRequiredTitle => 'Mise à jour requise';

  @override
  String updateRequiredBody(String current) {
    return 'Cette version de l’application ($current) n’est plus prise en charge par le serveur. Installez la dernière version pour continuer à utiliser CercaPosta.';
  }

  @override
  String get updateRequiredButton => 'Mettre à jour';

  @override
  String get updateStoreError =>
      'Impossible d’ouvrir la boutique. Mettez l’application à jour manuellement depuis l’App Store ou le Play Store.';

  @override
  String get emailPecSection => 'Enveloppe de transport PEC';

  @override
  String get emailPecTransportFrom => 'Transportée par';

  @override
  String get emailPecTransportSubject => 'Objet de l’enveloppe';

  @override
  String get emailPecTransportDate => 'Date du transport';

  @override
  String get emailPecDaticert => 'Certification (daticert.xml) présente';

  @override
  String get settingsStorage => 'Stockage';

  @override
  String settingsStorageValue(String used, String quota, String percent) {
    return '$used de $quota ($percent %)';
  }

  @override
  String settingsStorageUnlimited(String used) {
    return '$used · illimité';
  }

  @override
  String get errorInvalidCredentials => 'Identifiants incorrects';

  @override
  String get errorAccountBanned =>
      'Compte temporairement verrouillé en raison de trop de tentatives';

  @override
  String get errorInvalidToken =>
      'Session expirée, s\'il vous plaît connectez-vous à nouveau';

  @override
  String get errorInvalidRefresh =>
      'Session invalide, s\'il vous plaît vous connecter à nouveau';

  @override
  String get errorForbidden => 'Opération non autorisée';

  @override
  String get errorFeatureNotInPlan =>
      'Cette fonction n\'est pas incluse dans le plan actuel.';

  @override
  String get errorAdminNotOnMobile =>
      'Les fonctionnalités Admin ne sont pas disponibles sur mobile';

  @override
  String get errorTotpInvalidCode => 'Code non valide';

  @override
  String get errorTotpExpired => 'Code expiré. Veuillez vous reconnecter.';

  @override
  String get errorDekLocked =>
      'Archive verrouillée. Déverrouillez avec votre mot de passe.';

  @override
  String get errorRecoveryFailed =>
      'La récupération a échoué. Vérifiez votre code de récupération.';

  @override
  String get errorWeakPassword =>
      'Le mot de passe ne répond pas aux exigences de sécurité';

  @override
  String get errorTotpSetupRequired =>
      'Votre compte exige la vérification en deux étapes : configurez-la depuis le Web avant de vous connecter avec l’application.';

  @override
  String get errorChatNotConfigured => 'Chat IA non configuré';

  @override
  String errorChatLlmError(String detail) {
    return 'Erreur du modèle IA : $detail';
  }

  @override
  String get errorNotFound => 'Non trouvé';

  @override
  String get errorPreviewUnsupported => 'Aperçu non disponible pour ce format';

  @override
  String get errorPreviewFailed => 'Impossible de générer l\'aperçu';

  @override
  String get errorRawMissing => 'Fichier n\'est plus disponible';

  @override
  String get errorValidation => 'Données non valides';

  @override
  String get errorNetwork => 'Erreur réseau. Vérifiez votre connexion.';

  @override
  String get errorGeneric => 'Erreur inattendue';

  @override
  String get errorFollowupNotRemindable =>
      'Il n’est plus possible d’envoyer un rappel pour cette réponse attendue.';

  @override
  String get errorFollowupNotConfigured =>
      'Le modèle d\'analyse n\'est pas configuré sur ce serveur.';

  @override
  String get errorFollowupDraftFailed =>
      'Impossible de générer le rappel. Réessayez.';

  @override
  String get errorFollowupSendNoSource =>
      'Aucun compte d\'origine ne peut envoyer ce message.';

  @override
  String get errorSendConsentRequired =>
      'Le compte Microsoft 365 doit être réautorisé pour envoyer, à partir de l\'application web.';

  @override
  String get errorMailAuthFailed =>
      'L\'authentification du compte de messagerie a échoué.';

  @override
  String get errorMailSendFailed => 'Échec de l’envoi. Réessayez plus tard.';

  @override
  String get navFollowups => 'Réponses en attente';

  @override
  String get followupsTitle => 'Réponses en attente';

  @override
  String get followupsTabTheirTurn => 'En attente de réponse';

  @override
  String get followupsTabMyTurn => 'À répondre';

  @override
  String get followupsEmpty => 'Aucune attente ouverte.';

  @override
  String get followupsRecentlyClosed => 'Dernièrement fermé';

  @override
  String get followupsLoadMore => 'Charger plus';

  @override
  String get followupsDisabledTitle => 'Fonction non activée';

  @override
  String get followupsDisabledBody =>
      'Activez le suivi des réponses attendues depuis votre profil dans l’application Web.';

  @override
  String get followupsUnavailableTitle => 'Nécessite un serveur mis à jour';

  @override
  String get followupsUnavailableBody =>
      'Ce serveur ne propose pas encore le suivi des réponses attendues.';

  @override
  String get followupsPausedEndpoint =>
      'Analyse en pause : le point de terminaison de l’IA ne répond pas. La synchronisation de l’archive continue.';

  @override
  String get followupsPausedCap =>
      'Analyse en pause : plafond quotidien atteint.';

  @override
  String get followupsPausedBilling =>
      'Analyse en pause : limite IA de l’offre atteinte.';

  @override
  String get followupsActionOpen => 'Ouvrir la conversation';

  @override
  String get followupsActionReminder => 'Préparer le rappel';

  @override
  String get followupsActionDone => 'Terminé';

  @override
  String get followupsActionSnooze1 => 'Reporter de 1 jour';

  @override
  String get followupsActionSnooze3 => 'Reporter de 3 jours';

  @override
  String get followupsActionDismiss => 'Ignorer';

  @override
  String get followupsActionError => 'L\'action a échoué';

  @override
  String get followupsChipAnswered => 'Réponse reçue';

  @override
  String get followupsChipDismissed => 'Ignorée';

  @override
  String followupsChipSnoozed(String date) {
    return 'Reportée au $date';
  }

  @override
  String followupsChipReminded(String date) {
    return 'Rappel envoyé le $date';
  }

  @override
  String followupsChipRemindedMany(String date, int count) {
    return 'Rappel envoyé le $date ×$count';
  }

  @override
  String followupsChipOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'En retard de $days jours',
      one: 'En retard de 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get followupsChipDueToday => 'Attendu aujourd\'hui';

  @override
  String get followupsChipDueTomorrow => 'Attendu demain';

  @override
  String followupsChipDueOn(String date) {
    return 'Échéance le $date';
  }

  @override
  String get reminderTitle => 'Préparer le rappel';

  @override
  String get reminderGenerating => 'Générer un brouillon...';

  @override
  String get reminderFailed => 'Impossible de générer le brouillon.';

  @override
  String get reminderSubject => 'Objet';

  @override
  String get reminderMessage => 'Message';

  @override
  String get reminderRegister => 'Registre de langue';

  @override
  String get reminderRegisterAuto => 'Automatique';

  @override
  String get reminderRegisterTu => 'Informelle';

  @override
  String get reminderRegisterLei => 'Formel';

  @override
  String reminderRegisterUsed(String register, String source) {
    return 'Registre de langue : $register ($source)';
  }

  @override
  String get reminderRegisterSourceManual => 'choisi';

  @override
  String get reminderRegisterSourceContact => 'mémorisé pour le contact';

  @override
  String get reminderRegisterSourceDetected =>
      'détecté à partir de votre style';

  @override
  String get reminderRegisterSourceDefault => 'par défaut';

  @override
  String get reminderRememberContact => 'Mémoriser pour ce contact';

  @override
  String get reminderRemembered =>
      'Registre de langue mémorisé pour ce contact';

  @override
  String get reminderLanguage => 'Langue';

  @override
  String get reminderLanguageAuto => 'Automatique';

  @override
  String get reminderInstructionsHint =>
      'Instructions pour générer une nouvelle version (facultatif)';

  @override
  String get reminderRegenerate => 'Régénérer';

  @override
  String get reminderExpand => 'Plein écran';

  @override
  String get reminderInstructions => 'Instructions';

  @override
  String get reminderIncludeOriginal => 'Citer le courriel original à la fin';

  @override
  String get reminderAppendedNote =>
      'La signature, la mention de l’IA et l’éventuelle citation du message original sont ajoutées automatiquement.';

  @override
  String reminderSendFromNote(String from) {
    return 'L’e-mail sera envoyé depuis votre compte $from';
  }

  @override
  String get reminderPreview => 'Aperçu des courriels';

  @override
  String get reminderPreviewTitle => 'Aperçu des courriels';

  @override
  String get reminderSendNow => 'Envoyer depuis CercaPosta';

  @override
  String reminderSent(String from) {
    return 'Rappel envoyé par $from';
  }

  @override
  String notifFollowupNoReplyTitle(String name) {
    return '$name n\'a pas répondu';
  }

  @override
  String notifFollowupNoReplyBody(String summary, int days) {
    return '«$summary» — aucune réponse depuis $days jours.';
  }

  @override
  String notifFollowupReplyDueTitle(String name) {
    return 'Vous devez répondre à $name';
  }

  @override
  String notifFollowupReplyDueBody(String summary, int days) {
    return '«$summary» — l’échéance est dépassée depuis $days jours.';
  }

  @override
  String get notifChannelName => 'Notifications';

  @override
  String notifSummaryTitle(int count) {
    return '$count nouvelles notifications';
  }

  @override
  String get notifSummaryBody => 'Ouvrez CercaPosta pour toutes les consulter.';

  @override
  String get notifFollowupDueSoonTitle => 'Échéance proche';

  @override
  String notifFollowupDueSoonBody(String summary, String name, String date) {
    return '«$summary» — $name : échéance le $date.';
  }

  @override
  String notifFollowupReminderSentTitle(String name) {
    return 'Rappel envoyé à $name';
  }

  @override
  String notifFollowupReminderSentBody(String summary) {
    return '« $summary » — le rappel automatique a été envoyé.';
  }

  @override
  String get notifFollowupDigestTitle => 'Résumé des réponses attendues';

  @override
  String notifFollowupDigestBody(int overdue, int dueToday, int waitingMe) {
    return '$overdue en retard · $dueToday attendues aujourd’hui · $waitingMe réponses à envoyer.';
  }

  @override
  String get notifOpenConversation => 'Ouvrir la conversation';

  @override
  String get actionCopy => 'Copier';

  @override
  String get actionCopied => 'Copié au presse-papiers';

  @override
  String get emailHeadersTitle => 'En-têtes des messages';

  @override
  String get emailHeadersEmpty => 'Aucun en-tête disponible';

  @override
  String get followupMarkTitle => 'Marquer comme réponse attendue';

  @override
  String get followupMarkTheirTurn => 'J\'attends une réponse.';

  @override
  String get followupMarkTheirTurnHint =>
      'J\'ai écrit et j\'attends qu\'ils répondent.';

  @override
  String get followupMarkMyTurn => 'Je dois une réponse';

  @override
  String get followupMarkMyTurnHint =>
      'J’ai reçu un message et c’est à moi de répondre';

  @override
  String get followupMarkDue => 'Échéance (facultative)';

  @override
  String get followupMarkPickDue => 'Choisissez une date';

  @override
  String get followupMarkConfirm => 'Créer';

  @override
  String get followupMarkCreated => 'Marquée comme réponse attendue';

  @override
  String get errorFollowupAlreadyActive =>
      'Il y a déjà une attente ouverte sur cette conversation.';

  @override
  String get errorFollowupNoCounterpart =>
      'Ne peut pas dire qui devrait répondre: essayez l\'autre direction.';

  @override
  String get memoryTitle => 'Mémoire du chat';

  @override
  String get memorySettingsHint => 'Ce que l\'assistant a appris sur vous';

  @override
  String get memoryIntro =>
      'Voici tout ce que l’assistant a appris sur vous : comment vous appelez les personnes, comment vous préférez les listes et les faits qu’il tient pour acquis. Chaque élément peut être mis en pause ou oublié, et rien n’est appris sans vous en informer. Pour ajouter un souvenir, écrivez dans le chat : «Retenez que…».';

  @override
  String get memoryPolicyLearn => 'Apprendre de mes conversations';

  @override
  String get memoryPolicyLearnHint =>
      'Lorsque cette option est activée, l’assistant propose ce qu’il remarque pendant votre travail. Il vous en informe chaque fois et vous pouvez annuler. Si vous la désactivez, seuls les souvenirs que vous écrivez vous-même restent.';

  @override
  String get memoryPolicyEnabled => 'Utiliser la mémoire dans les réponses';

  @override
  String get memoryPolicyEnabledHint =>
      'Désactiver cette option conserve tous les souvenirs mais cesse de les appliquer : il s’agit d’une pause, pas d’une suppression.';

  @override
  String memoryAnnounceAlias(String key, String value) {
    return 'J\'ai appris que pour vous « $key » signifie $value .';
  }

  @override
  String memoryAnnounceGeneric(String key, String value) {
    return 'J\'ai appris : $key → $value .';
  }

  @override
  String memoryAnnounceTrial(String what) {
    return '$what Je conserve ce souvenir à l’essai pour l’instant, sans encore l’utiliser.';
  }

  @override
  String get memoryAnnounceUndo => 'Annuler';

  @override
  String get memoryAnnounceUndone => 'Annulé : je ne l’ai pas conservé.';

  @override
  String get memoryAnnounceRejected => 'D\'accord, je ne le proposerai plus.';

  @override
  String memoryAppliedNote(String list) {
    return 'Depuis la mémoire : $list';
  }

  @override
  String get memoryListEmpty =>
      'Rien en mémoire pour l’instant. Vous pouvez écrire dans le chat : «Retenez que…».';

  @override
  String get memoryListEmptyFiltered => 'Pas de souvenirs dans cet état.';

  @override
  String get memoryFilterAll => 'Tous';

  @override
  String get memoryFilterActive => 'Actif';

  @override
  String get memoryFilterTrial => 'À l’essai';

  @override
  String get memoryFilterRejected => 'Refusé';

  @override
  String get memoryFilterDisabled => 'Pausées';

  @override
  String get memoryStatusActive => 'Actif';

  @override
  String get memoryStatusTrial => 'À l’essai';

  @override
  String get memoryStatusRejected => 'Refusé';

  @override
  String get memoryStatusDisabled => 'Pausées';

  @override
  String get memoryStatusTrialHint =>
      'encore en cours d’apprentissage, pas encore utilisé';

  @override
  String get memoryStatusStaleHint =>
      'non utilisé pendant des mois : arrêtez-le si vous n\'en avez plus besoin';

  @override
  String get memoryKindAlias => 'Comment vous appelez les personnes';

  @override
  String get memoryKindParam => 'Comment vous voulez des recherches';

  @override
  String get memoryKindRender => 'Vos préférences de présentation des listes';

  @override
  String get memoryKindFact => 'Faits à garder à l\'esprit';

  @override
  String get memoryKindShortcut => 'Questions récurrentes';

  @override
  String get memoryTriggerSearch => 'lors de la recherche';

  @override
  String get memoryTriggerListing => 'dans les listes';

  @override
  String get memoryTriggerContact => 'sur les contacts';

  @override
  String get memoryTriggerAlways => 'toujours';

  @override
  String get memorySourceExplicit => 'Vous l\'avez dit.';

  @override
  String get memorySourceCorrection => 'à partir d’une de vos corrections';

  @override
  String get memorySourceRecurrence => 'd\'une habitude';

  @override
  String get memorySourceSuggested => 'proposé par l\'archive';

  @override
  String get memorySourceInferred =>
      'déduit de quelque chose que vous avez écrit';

  @override
  String memoryUsedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'utilisé $count fois',
      one: 'utilisé une fois',
    );
    return '$_temp0';
  }

  @override
  String get memoryEnable => 'Reprendre';

  @override
  String get memoryDisable => 'Pause';

  @override
  String get memoryReject => 'Ne jamais mémoriser ceci';

  @override
  String get memoryUnreject => 'J\'ai changé d\'avis.';

  @override
  String get memoryDelete => 'Supprimer';

  @override
  String memoryDeleteConfirm(String key) {
    return 'Supprimer le souvenir «$key» ? Si vous préférez qu’il ne soit plus jamais proposé, utilisez «Ne jamais mémoriser ceci».';
  }

  @override
  String get memorySuggestionsTitle => 'Aliases proposées par votre archive';

  @override
  String get memorySuggestionsHint =>
      'Noms qui ne peuvent désigner qu’une seule personne dans votre archive. Si vous acceptez une suggestion, utiliser ce nom dans le chat lancera directement une recherche sur son adresse.';

  @override
  String get memorySuggestionsAccept => 'Accepter';

  @override
  String memorySuggestionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count e-mails',
      one: '1 e-mail',
    );
    return '$_temp0';
  }

  @override
  String get diagnosticsTitle => 'Diagnostic';

  @override
  String get diagnosticsIntro =>
      'Si tout ce qui a été importé est réellement consultable. Quand quelque chose manque, vous obtenez la raison et, là où il y en a une, quoi faire à ce sujet.';

  @override
  String get diagnosticsStatusOk =>
      'Tout va bien : l\'archive est complète et consultable.';

  @override
  String get diagnosticsStatusWorking =>
      'Traitement en cours : une partie de l’archive ne peut pas encore être recherchée. Vous n’avez rien à faire.';

  @override
  String get diagnosticsStatusAttention =>
      'Certains éléments ci-dessous méritent votre attention.';

  @override
  String get diagnosticsMessages => 'Messages dans la recherche AI';

  @override
  String get diagnosticsAttachments =>
      'Texte lu à l\'intérieur des pièces jointes';

  @override
  String diagnosticsOf(String done, String total) {
    return '$done de $total';
  }

  @override
  String diagnosticsAttachmentsPending(String n) {
    return '$n pièces jointes en attente';
  }

  @override
  String diagnosticsMessagesPending(String n) {
    return '$n messages en attente';
  }

  @override
  String get diagnosticsEmbeddingOff => 'Recherche AI désactivée';

  @override
  String get diagnosticsEmbeddingPaused => 'pause : limites du plan d\'IA';

  @override
  String get diagnosticsEmbeddingActive => 'file d\'attente en cours';

  @override
  String diagnosticsEmbeddingLastError(String when, String detail) {
    return 'dernière erreur ( $when): $detail';
  }

  @override
  String diagnosticsRetryAll(String n) {
    return 'Réessayer pour $n pièces jointes';
  }

  @override
  String get diagnosticsRetryHint =>
      'Le traitement a été interrompu par un incident temporaire : une nouvelle tentative peut réussir.';

  @override
  String diagnosticsRetryExhaustedHint(String n) {
    return '$n de ces pièces jointes ont déjà épuisé leurs cinq tentatives automatiques : réessayez si la cause du blocage a été résolue.';
  }

  @override
  String diagnosticsReasonsTitle(String n) {
    return 'Pourquoi $n pièces jointes n’ont pas de texte';
  }

  @override
  String diagnosticsExpectedTitle(String n) {
    return '$n pièces jointes n’étaient pas des documents à lire';
  }

  @override
  String diagnosticsEmbedReasonsTitle(String n) {
    return 'Pourquoi $n messages ne figurent pas dans la recherche IA';
  }

  @override
  String get diagnosticsActionRetry => 'Réessayer';

  @override
  String get diagnosticsActionAskAdmin =>
      'Intervention de l’administrateur nécessaire';

  @override
  String get diagnosticsActionNone => 'Rien à faire';

  @override
  String get diagnosticsReasonTikaHttpError =>
      'Le lecteur de documents ne répondait pas';

  @override
  String get diagnosticsReasonTikaTimeout => 'Le document a pris trop de temps';

  @override
  String get diagnosticsReasonTikaServerError =>
      'Le lecteur de documents a retourné une erreur';

  @override
  String get diagnosticsReasonTikaBusy =>
      'Le lecteur de documents est temporairement occupé';

  @override
  String get diagnosticsReasonTikaPartial =>
      'Seule une partie du texte du document a été récupérée.';

  @override
  String get diagnosticsReasonTikaInvalidLimits =>
      'Les limites d\'extraction sont invalides : contactez l\'administrateur';

  @override
  String get diagnosticsReasonTikaRejected =>
      'Le lecteur de documents a refusé le fichier';

  @override
  String get diagnosticsReasonTikaUnsupported =>
      'Un type de fichier que je ne peux pas lire';

  @override
  String get diagnosticsReasonExtractBacklogError =>
      'Erreur inattendue lors de la lecture';

  @override
  String get diagnosticsReasonUnmatchedPart =>
      'Pièce jointe non trouvée dans le message';

  @override
  String get diagnosticsReasonOverSizeLimit =>
      'Plus grande que la limite autorisée';

  @override
  String get diagnosticsReasonEmpty => 'Fichier vide';

  @override
  String get diagnosticsReasonSignatureFile =>
      'Signature numérique, pas un document';

  @override
  String get diagnosticsReasonInlineImage =>
      'Image intégrée dans le message (logo, signature)';

  @override
  String get diagnosticsReasonUnknown => 'Cause non enregistrée';

  @override
  String get diagnosticsSettingsHint =>
      'Si tout ce que vous importez est vraiment consultable, et ce qui manque';

  @override
  String get billingTitle => 'Offre et paiements';

  @override
  String get billingSettingsHint =>
      'Offre actuelle, renouvellement et modifications prévues';

  @override
  String get billingCurrentPlan => 'Offre actuelle';

  @override
  String get billingNoPlan => 'Aucune offre active.';

  @override
  String get billingStatus => 'État';

  @override
  String get billingPaymentMethod => 'Mode de paiement';

  @override
  String get billingRecurringPrice => 'Prix récurrent';

  @override
  String get billingPeriodEnd => 'Fin de période';

  @override
  String get billingPlanValidity => 'Validité de l’offre';

  @override
  String get billingNoExpiration => 'Pas d\'expiration';

  @override
  String get billingPeriodicity => 'Fréquence de facturation';

  @override
  String get billingIntervalMonthly => 'Mensuel';

  @override
  String get billingIntervalAnnual => 'Annuel';

  @override
  String get billingNextRenewal => 'Prochain renouvellement';

  @override
  String get billingNextRenewalAmount => 'Montant du prochain renouvellement';

  @override
  String get billingDateUnavailable => 'Date non encore disponible';

  @override
  String get billingGraceUntil => 'Délai de grâce jusqu\'à';

  @override
  String get billingPendingChanges => 'Changements d’offre';

  @override
  String get billingEffectiveAt => 'Date d\'entrée en vigueur';

  @override
  String get billingAmountDue => 'Montant prévu';

  @override
  String get billingManageInBrowser => 'Gérer l’offre et les paiements';

  @override
  String get billingExternalCheckoutHint =>
      'Pour protéger votre paiement, la finalisation de l’achat, les nouvelles tentatives de paiement et les annulations se font dans l’espace sécurisé de CercaPosta dans votre navigateur.';

  @override
  String get billingStatusActive => 'Actif';

  @override
  String get billingStatusFree => 'Gratuit';

  @override
  String get billingStatusPastDue => 'Paiement en retard';

  @override
  String get billingStatusSuspended => 'Suspendu';

  @override
  String get billingStatusCanceled => 'Annulé';

  @override
  String get billingProviderManual => 'Paiement manuel';

  @override
  String get billingChangePendingAcceptance =>
      'En attente de votre acceptation';

  @override
  String get billingChangePendingPayment => 'En attente de paiement';

  @override
  String get billingChangeScheduled => 'Prévu';

  @override
  String get billingChangeProcessing => 'Traitement';

  @override
  String get billingChangePaymentGrace => 'Paiement échoué · délai de grâce';

  @override
  String get billingChangeCanceling => 'Annulation en cours';

  @override
  String get notifPlanChangeProposalTitle =>
      'Vous avez une proposition de changement de plan';

  @override
  String get notifPlanChangeProposalBody =>
      'Ouvrez «Offre et paiements» pour examiner le prix, le crédit et la date d’effet.';

  @override
  String get notifPlanChangeProposalExpiringTitle =>
      'La proposition va bientôt expirer.';

  @override
  String notifPlanChangeProposalExpiringBody(String date) {
    return 'Examinez la proposition avant le $date.';
  }

  @override
  String get notifPlanChangeExpiredTitle => 'Le changement d’offre a expiré';

  @override
  String get notifPlanChangeExpiredBody =>
      'Le changement n\'a pas été appliqué et votre plan précédent est demeuré inchangé.';

  @override
  String get notifPlanChangeScheduledTitle => 'Le changement de plan est prévu';

  @override
  String notifPlanChangeScheduledBody(String date) {
    return 'Le changement prendra effet le $date ; votre offre actuelle reste active jusque-là.';
  }

  @override
  String get notifPlanChangeAppliedTitle => 'Votre nouveau plan est actif';

  @override
  String get notifPlanChangeAppliedBody =>
      'Vos nouveaux quotas et fonctionnalités sont désormais disponibles.';

  @override
  String get notifPlanChangeCanceledTitle =>
      'Le changement d’offre a été annulé';

  @override
  String get notifPlanChangeCanceledBody =>
      'Votre plan actuel demeure inchangé.';

  @override
  String get notifPlanChangePaymentFailedTitle => 'Le paiement a échoué';

  @override
  String notifPlanChangePaymentFailedBody(String date) {
    return 'Votre offre précédente reste active. Réessayez le paiement avant le $date.';
  }

  @override
  String get notifPlanChangeRetryTitle => 'Vous pouvez réessayer le paiement';

  @override
  String get notifPlanChangeRetryBody =>
      'Ouvrez «Offre et paiements» pour effectuer une nouvelle tentative.';

  @override
  String get notifPlanChangeGraceExpiringTitle =>
      'Le délai de grâce est sur le point de se terminer';

  @override
  String notifPlanChangeGraceExpiringBody(String date) {
    return 'Effectuez le paiement avant le $date.';
  }

  @override
  String get notifPlanChangeGraceExpiredTitle => 'Le délai de grâce a pris fin';

  @override
  String get notifPlanChangeGraceExpiredBody =>
      'Le changement n\'a pas été appliqué parce que le paiement n\'a pas été effectué.';

  @override
  String get notifPlanChangeActionRequiredTitle =>
      'Le changement de plan a besoin d\'aide';

  @override
  String get notifPlanChangeActionRequiredBody =>
      'Consultez «Offre et paiements» ou contactez l’assistance.';

  @override
  String get passkeyUnsupportedServer =>
      'Les clés d’accès ne sont pas disponibles pour ce serveur dans cette version de l’application. Utilisez votre mot de passe, Google ou Apple ; vous pouvez gérer les clés d’accès sur le site Web du serveur.';

  @override
  String get searchVoiceLocalUnavailable =>
      'La reconnaissance locale n’est pas disponible pour cette langue ou cet appareil. Utilisez le clavier ; Android nécessite Android 12 ou une version ultérieure et un service de reconnaissance locale installé.';

  @override
  String get deliveryHistory => 'Résultats d’envoi';

  @override
  String get deliveryReference => 'Référence d’envoi';

  @override
  String get deliverySending => 'Envoi';

  @override
  String get deliverySent => 'Accepté par le service de messagerie';

  @override
  String get deliveryFailed => 'Non envoyé';

  @override
  String get deliveryUnknown => 'Résultat à vérifier';

  @override
  String get deliveryChecked =>
      'J’ai vérifié le résultat auprès du service de messagerie et confirmé que la tentative n’est plus en cours. Si le processus était bloqué, je l’ai fait arrêter.';

  @override
  String get deliveryConfirmSent => 'Confirmer l\'acceptation';

  @override
  String get deliveryConfirmFailed => 'Confirmer l’absence d’envoi';

  @override
  String get deliveryResolved =>
      'Résultat enregistré. Aucun nouveau message n\'a été envoyé.';

  @override
  String get deliveryEmpty => 'Aucune tentative de livraison enregistrée.';

  @override
  String get errorDeliveryUnknown =>
      'Le service de messagerie a peut-être accepté le message. Consultez «Résultats d’envoi» et vérifiez auprès du fournisseur avant de réessayer.';

  @override
  String get errorDeliverySending =>
      'Une livraison de cette réponse en attente est déjà en cours. Ne réessayez pas.';

  @override
  String get errorDeliveryConflict =>
      'Cette demande a déjà été traitée ou contient un contenu différent. Consultez «Résultats d’envoi».';

  @override
  String get errorDeliveryCheckRequired =>
      'Vérifiez le résultat auprès du service de messagerie avant de le confirmer.';

  @override
  String get errorMailNotAccepted =>
      'La tentative a échoué avant l\'acceptation du service de courrier. Réglez le problème et réessayez.';

  @override
  String get errorMailDeliveryUnknown =>
      'Le résultat est incertain. Vérifiez auprès du service de courrier avant de réessayer.';

  @override
  String get biometricErrorCancelled =>
      'Vérification biométrique annulée. Vous pouvez vous connecter avec votre mot de passe.';

  @override
  String get biometricErrorUnavailable =>
      'Le stockage biométrique est indisponible. Utilisez votre mot de passe ; si vous avez modifié vos empreintes digitales ou Face ID, réactivez la biométrie dans les paramètres.';

  @override
  String get biometricErrorReenroll =>
      'L’autorisation de cet appareil a expiré ou n’est plus valide. Connectez-vous manuellement et réactivez la biométrie dans les paramètres.';

  @override
  String get errorReauthenticationRequired =>
      'Pour des raisons de sécurité, déconnectez-vous puis reconnectez-vous avec votre méthode habituelle. Activez ensuite la biométrie dans les 5 minutes.';

  @override
  String get aiReportAction => 'Signaler la réponse';

  @override
  String get aiReportTitle => 'Signaler une réponse de l’IA';

  @override
  String get aiReportIntro =>
      'La réponse et votre commentaire seront envoyés en toute sécurité aux administrateurs pour examen.';

  @override
  String get aiReportReason => 'Motifs';

  @override
  String get aiReportReasonMisleading => 'Trompeuse ou incorrecte';

  @override
  String get aiReportReasonHarmful => 'Nocif';

  @override
  String get aiReportReasonIllegal => 'Contenu illégal';

  @override
  String get aiReportReasonPrivacy => 'Problème de confidentialité';

  @override
  String get aiReportReasonOther => 'Autres';

  @override
  String get aiReportComment => 'Commentaire facultatif';

  @override
  String get aiReportCommentHint =>
      'Expliquez ce qui ne va pas avec la réponse';

  @override
  String get aiReportSend => 'Envoyer un rapport';

  @override
  String get aiReportSent => 'Rapport envoyé';

  @override
  String get aiReportAlreadySent => 'Cette réponse a déjà été signalée';

  @override
  String get tagsTitle => 'Étiquettes';

  @override
  String get tagsAssignHint =>
      'Attribuez des étiquettes à ce message ou gérez les étiquettes disponibles';

  @override
  String get tagsManageMessage => 'Gérer les étiquettes';

  @override
  String get tagsEmpty => 'Vous n’avez pas encore créé d’étiquettes.';

  @override
  String get tagsCreate => 'Créer une étiquette';

  @override
  String get tagsCreateTitle => 'Nouvelle étiquette';

  @override
  String get tagsEdit => 'Modifier';

  @override
  String get tagsEditTitle => 'Éditer l\'étiquette';

  @override
  String get tagsDelete => 'Supprimer';

  @override
  String get tagsDeleteTitle => 'Supprimer l\'étiquette';

  @override
  String tagsDeleteConfirm(String name) {
    return 'Supprimer l’étiquette «$name» de toute l’archive ?';
  }

  @override
  String get tagsName => 'Nom';

  @override
  String get actionDone => 'Terminé';

  @override
  String get errorTagNameRequired => 'Saisissez un nom pour l\'étiquette.';

  @override
  String get errorTagNameTaken => 'Une étiquette portant ce nom existe déjà.';

  @override
  String get errorTagInvalidColor =>
      'La couleur sélectionnée n\'est pas valide.';

  @override
  String get errorAiReportMessageNotFound =>
      'Cette réponse ne peut plus être signalée.';

  @override
  String get errorAiReportAssistantOnly =>
      'Seules les réponses de l’assistant peuvent être signalées.';

  @override
  String get settingsLanguageUiHint =>
      'Ce choix ne s\'applique qu\'à l\'interface de cet appareil.';

  @override
  String get settingsProfileLanguage =>
      'Langue des e-mails, des reçus et des réponses de l’IA';

  @override
  String get settingsProfileLanguageHint =>
      'Utilisée pour les e-mails, les reçus et les réponses de l’IA. Les reçus d’un espace de travail partagé suivent la préférence de son propriétaire. La langue de l’interface ainsi que les formats de date et de nombre restent indépendants. Les reçus déjà émis ne changent pas.';

  @override
  String get searchVoiceChooseLanguage =>
      'Langue et variante pour la dictée locale';

  @override
  String get searchVoiceHint =>
      'La dictée locale. Appuyez et maintenez pour choisir une langue et une variante.';
}
