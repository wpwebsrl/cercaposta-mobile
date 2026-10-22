// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get personalAiLabel => 'IA personal';

  @override
  String get managedAiLabel => 'IA de CercaPosta';

  @override
  String get errorPersonalAiUnavailable =>
      'La IA personal está en pausa: revisa tu plan, el consentimiento y el desbloqueo del archivo en la configuración web.';

  @override
  String get errorSessionChanged =>
      'La sesión ha cambiado. Inténtalo de nuevo con la cuenta actual.';

  @override
  String get appName => 'CercaPosta';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionApply => 'Aplicar';

  @override
  String get actionClear => 'Limpiar';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionRemove => 'Quitar';

  @override
  String get actionOpenInBrowser => 'Abrir en el navegador';

  @override
  String get loading => 'Cargando…';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get serverTitle => 'Elegir servidor';

  @override
  String get serverSubtitle =>
      'Introduce la dirección de tu servidor de CercaPosta.';

  @override
  String get serverUrlLabel => 'Dirección del servidor';

  @override
  String get serverUrlHint => 'https://mail.example.com';

  @override
  String get serverValidating => 'Validando el servidor…';

  @override
  String get serverInvalid => 'Dirección no válida o servidor inaccesible';

  @override
  String get serverNotCercaPosta =>
      'Este servidor no es una instancia de CercaPosta';

  @override
  String get serverSavedTitle => 'Servidores guardados';

  @override
  String get serverNeedsSetup =>
      'Este servidor aún debe configurarse desde la web.';

  @override
  String get serverUpdateRequired =>
      'Actualiza la aplicación para usar este servidor.';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginHeading => 'Iniciar sesión en CercaPosta';

  @override
  String get loginTagline =>
      'Tu archivo de correo, accesible desde cualquier lugar';

  @override
  String get loginUsername => 'Nombre de usuario';

  @override
  String get loginPassword => 'Contraseña';

  @override
  String get loginButton => 'Iniciar sesión';

  @override
  String get loginPasskey => 'Iniciar sesión con una clave de acceso';

  @override
  String get loginGoogle => 'Continuar con Google';

  @override
  String get loginApple => 'Iniciar sesión con Apple';

  @override
  String get loginChangeServer => 'Cambiar de servidor';

  @override
  String get loginBiometric => 'Iniciar sesión con biometría';

  @override
  String get loginBiometricReason => 'Acceder a tu archivo de correo';

  @override
  String get loginEnableBiometricTitle => 'Inicio de sesión rápido';

  @override
  String get loginEnableBiometricBody =>
      '¿Quieres usar Face ID o tu huella la próxima vez? Este dispositivo guardará una autorización revocable protegida mediante biometría. La aplicación no guardará la contraseña de tu cuenta.';

  @override
  String sharedFromLabel(String name) {
    return 'de $name';
  }

  @override
  String sharedReaderBanner(String name) {
    return 'Carpeta compartida por $name — solo lectura';
  }

  @override
  String get totpTitle => 'Verificación en dos pasos';

  @override
  String get totpSubtitle =>
      'Introduce el código de tu aplicación de autenticación.';

  @override
  String get totpCode => 'Código de 6 dígitos';

  @override
  String get totpButton => 'Verificar';

  @override
  String get unlockTitle => 'Desbloquear archivo';

  @override
  String get unlockDescription =>
      'Tu archivo está cifrado. Introduce tu contraseña para acceder a su contenido.';

  @override
  String get unlockPassword => 'Contraseña';

  @override
  String get unlockButton => 'Desbloquear';

  @override
  String get unlockBiometric => 'Desbloquear con biometría';

  @override
  String get unlockEnableBiometricTitle => 'Desbloqueo rápido';

  @override
  String get unlockEnableBiometricBody =>
      '¿Quieres usar Face ID o tu huella para desbloquear el archivo? Este dispositivo guardará una autorización revocable protegida mediante biometría.';

  @override
  String get unlockEnableBiometricYes => 'Sí, habilitar';

  @override
  String get unlockEnableBiometricNo => 'No, gracias';

  @override
  String get unlockReason => 'Desbloquear tu archivo cifrado';

  @override
  String get firstPasswordTitle => 'Establecer una nueva contraseña';

  @override
  String get firstPasswordSubtitle =>
      'En el primer acceso debes elegir una contraseña personal (el administrador nunca la conocerá).';

  @override
  String get firstPasswordNew => 'Nueva contraseña';

  @override
  String get firstPasswordConfirm => 'Confirmar contraseña';

  @override
  String get firstPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get kitTitle => 'Kit de emergencia';

  @override
  String get kitBody =>
      'Guarda este código en un lugar seguro: permite recuperar tu archivo si olvidas la contraseña. SOLO se muestra ahora.';

  @override
  String get kitCopy => 'Copiar';

  @override
  String get kitCopied => 'Copiado al portapapeles';

  @override
  String get recoveryTitle => 'Recuperación del archivo';

  @override
  String get recoverySubtitle =>
      'El administrador ha restablecido tu contraseña. Introduce el código del kit de emergencia y elige una contraseña nueva.';

  @override
  String get recoverySecretLabel => 'Código de recuperación';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navChat => 'Chat de IA';

  @override
  String get navSettings => 'Configuración';

  @override
  String get navNotifications => 'Avisos';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsEmpty => 'No hay notificaciones.';

  @override
  String get notificationsDismiss => 'Descartar';

  @override
  String get notificationsDismissAll => 'Eliminar todas';

  @override
  String get notificationsDismissAllConfirm =>
      '¿Eliminar todas las notificaciones? Esta acción no se puede deshacer.';

  @override
  String get notifReprocessTitle =>
      'Reprocesa tu archivo para aplicar las últimas actualizaciones';

  @override
  String get notifReprocessBody =>
      'Una actualización de la aplicación ha mejorado el tratamiento de los correos ya archivados (por ejemplo, las imágenes incrustadas en las firmas ya no cuentan como adjuntos). El reprocesamiento se inicia desde la aplicación web.';

  @override
  String get searchHint => 'Buscar… (from:, tag:, has:pdf…)';

  @override
  String get searchVoice => 'Búsqueda por voz';

  @override
  String get searchVoiceListening => 'Escuchando…';

  @override
  String get searchVoiceUnavailable => 'Reconocimiento de voz no disponible';

  @override
  String get searchVoicePermission => 'Permiso de micrófono denegado';

  @override
  String get searchFilters => 'Filtros';

  @override
  String get searchNoResults => 'Sin resultados';

  @override
  String get searchNewResults => 'Nuevos resultados';

  @override
  String get sortTooltip => 'Ordenar resultados';

  @override
  String get sortRelevance => 'Relevancia';

  @override
  String get sortNewest => 'Más recientes';

  @override
  String get sortOldest => 'Más antiguos';

  @override
  String get searchLoading => 'Buscando…';

  @override
  String get searchEmptyPrompt =>
      'Busca en tu archivo con palabras clave u operadores.';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
      zero: 'Sin resultados',
    );
    return '$_temp0';
  }

  @override
  String attachmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adjuntos',
      one: '1 adjunto',
    );
    return '$_temp0';
  }

  @override
  String get filtersTitle => 'Filtros';

  @override
  String get filterFrom => 'De';

  @override
  String get filterTo => 'Para / CC';

  @override
  String get filterSubject => 'Asunto';

  @override
  String get filterHasAttachments => 'Con archivos adjuntos';

  @override
  String get filterAttachmentExt => 'Tipo de adjunto (p. ej., pdf)';

  @override
  String get filterDateFrom => 'Después de';

  @override
  String get filterDateTo => 'Antes de';

  @override
  String get filterTags => 'Etiquetas';

  @override
  String get filterFolders => 'Carpetas';

  @override
  String get foldersTitle => 'Carpetas';

  @override
  String get foldersAll => 'Todas las carpetas';

  @override
  String get foldersRefresh => 'Actualizar';

  @override
  String get foldersEmpty => 'No hay carpetas en el archivo';

  @override
  String get foldersExpand => 'Expandir';

  @override
  String get foldersCollapse => 'Contraer';

  @override
  String foldersMultiple(int count) {
    return '$count carpetas';
  }

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get aboutCompany => 'WpWeb S.r.l.';

  @override
  String get aboutBuildLabel => 'compilación';

  @override
  String get aboutWebsite => 'Visitar wpweb.com';

  @override
  String get aboutCredits =>
      'CercaPosta es un producto de WpWeb: un archivo de correo inteligente, cifrado y con búsqueda.\nTodo tu correo, por fin en un solo lugar.\nAños de mensajes, conversaciones y adjuntos, reunidos y ordenados.\nSe acabaron los buzones dispersos, las copias de seguridad antiguas y los archivos olvidados.\nCercaPosta lo reúne todo en un archivo seguro, siempre a tu alcance.\nEncontrar un correo deja de ser una búsqueda del tesoro.\nEscribe lo que recuerdes, como lo dirías en voz alta.\nUn nombre, una fecha, una palabra: los resultados aparecen al instante.\n¿No recuerdas las palabras exactas? No hay problema.\nCercaPosta comprende el significado de tu búsqueda, no solo las palabras.\n¿Buscas «la cotización del fontanero del año pasado»?\nLa encuentra, aunque ese correo nunca usara la palabra «cotización».\nTambién hay un asistente inteligente que lee tu correo por ti.\nHazle preguntas con tus propias palabras y recibe respuestas claras.\n«¿Cuándo confirmé la cita con el dentista?»\n«¿Cuál es el IBAN que me envió el proveedor?»\nResponde citando los correos correctos, para que siempre puedas comprobarlo.\nLos adjuntos también se pueden buscar.\nPDF, documentos, hojas de cálculo e incluso el texto dentro de las imágenes.\nEsa factura, ese contrato, esa foto: a una búsqueda de distancia.\nSe acabaron las horas recorriendo la bandeja de entrada para encontrar un detalle.\nFiltra por carpeta, etiqueta, remitente o fecha.\nAcota la búsqueda con unos clics y ve directo a lo que necesitas.\nCada mensaje se abre de forma clara y fácil de leer.\nY, sobre todo, tus datos siguen siendo tuyos, y solo tuyos.\nTodo se cifra en reposo con tu clave personal.\nUna base de datos o copia de seguridad robada sigue siendo ilegible.\nLa clave de seguridad es tuya y solo tuya.\nCercaPosta es un archivo de solo lectura.\nNunca envía, responde ni cambia nada en tus buzones originales.\nConserva y protege, sin modificar nunca el origen.\nEstá pensado para quienes tienen mucho correo y poco tiempo.\nProfesionales, empresas, despachos, oficinas e instituciones.\nFácil de usar para cualquiera.\nSin manuales ni complicaciones.\nÁbrelo, escribe lo que buscas y encuéntralo. Eso es todo.\nLa memoria de tu correspondencia, siempre contigo.\nLo que necesitas, justo cuando lo necesitas.\nRecupera en segundos lo que creías perdido para siempre.\nEncuentra información, acuerdos y decisiones tomadas por correo.\nConvierte años de correo en un recurso vivo en el que puedes buscar.\nMás orden, menos estrés.\nMás tiempo para lo que de verdad importa.\nRápido al buscar, discreto al conservar.\nFiable siempre que lo necesitas.\nSeguro por diseño, sencillo por elección.\nTu archivo de correo, inteligente y protegido.\nBúsqueda en todo, claridad desde el principio.\nCercaPosta: encuentra todo, no pierdas nada.\nUn producto de WpWeb.\nTecnología que simplifica la vida digital.\nGracias por elegir CercaPosta.';

  @override
  String get emailLoading => 'Cargando mensaje…';

  @override
  String get emailNoBody => 'No hay contenido que mostrar.';

  @override
  String get emailRawMissing =>
      'El mensaje original ya no está disponible: solo se muestran los metadatos.';

  @override
  String get emailAttachments => 'Adjuntos';

  @override
  String get emailThread => 'Conversación';

  @override
  String get emailOpenAttachment => 'Abrir adjunto';

  @override
  String get emailShowRemoteImages => 'Mostrar imágenes remotas';

  @override
  String get emailAlwaysShowRemoteImagesFromSender =>
      'Mostrar siempre las de este remitente';

  @override
  String get emailPecBadge => 'PEC';

  @override
  String get emailTo => 'Para';

  @override
  String get emailCc => 'CC';

  @override
  String get emailDate => 'Fecha';

  @override
  String get emailFrom => 'De';

  @override
  String get emailDetails => 'Detalles';

  @override
  String get emailThreadEmpty => 'No hay más mensajes en esta conversación.';

  @override
  String get attachmentLoading => 'Cargando vista previa…';

  @override
  String get attachmentUnsupported =>
      'La vista previa no está disponible para este tipo de archivo.';

  @override
  String get chatTitle => 'Chat de IA';

  @override
  String get chatHint => 'Haz una pregunta sobre tu archivo…';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatNotConfigured =>
      'El chat de IA no está configurado en este servidor.';

  @override
  String get chatDisabled => 'El chat de IA está desactivado en este servidor.';

  @override
  String get chatNew => 'Nueva conversación';

  @override
  String get chatHistory => 'Historial';

  @override
  String get chatHistoryEmpty => 'No hay conversaciones guardadas.';

  @override
  String get chatCitations => 'Fuentes';

  @override
  String get chatPhaseUnderstanding => 'Interpretando…';

  @override
  String get chatPhaseSearching => 'Buscando…';

  @override
  String get chatPhaseEmbedding => 'Análisis semántico…';

  @override
  String get chatPhaseReranking => 'Reordenando…';

  @override
  String get chatPhaseGenerating => 'Generando respuesta…';

  @override
  String chatActivitySearch(String q) {
    return 'Buscando: «$q»';
  }

  @override
  String chatActivityThread(String s) {
    return 'Leyendo el hilo «$s»';
  }

  @override
  String get chatActivityThreadGeneric => 'Leyendo una conversación';

  @override
  String get chatActivityFollowups =>
      'Comprobando el seguimiento de respuestas';

  @override
  String get chatActivityStats => 'Calculando estadísticas del archivo';

  @override
  String chatActivityContact(String a) {
    return 'Recopilando el historial de $a';
  }

  @override
  String chatActivityAttachments(String q) {
    return 'Leyendo adjuntos: «$q»';
  }

  @override
  String get chatActivityAttachmentsGeneric => 'Leyendo adjuntos';

  @override
  String chatCitationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count correos',
      one: '1 correo',
    );
    return '$_temp0';
  }

  @override
  String chatCitationsOthers(int count) {
    return 'y $count más';
  }

  @override
  String chatCitationsShowAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostrar los otros $count',
      one: 'Mostrar el último',
    );
    return '$_temp0';
  }

  @override
  String get chatCitationsUnusedLegend =>
      'En gris: correos leídos que no se usaron en la respuesta.';

  @override
  String chatPagingRead(int read, int total) {
    return 'Se han leído $read de $total correos para esta búsqueda.';
  }

  @override
  String chatPagingAll(int total) {
    return 'Se han leído los $total correos para esta búsqueda.';
  }

  @override
  String get chatEmbeddingFailed =>
      'Búsqueda semántica no disponible: los resultados usan solo palabras clave.';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsLegalAndSupport => 'Información legal y soporte';

  @override
  String get legalPrivacy => 'Política de privacidad';

  @override
  String get legalTerms => 'Condiciones de uso';

  @override
  String get legalSupport => 'Soporte';

  @override
  String get legalSupportHint =>
      'Contactos, teléfono y formas de solicitar ayuda';

  @override
  String get googleErrorCancelled =>
      'Se canceló el inicio de sesión con Google';

  @override
  String get googleErrorState =>
      'La sesión de Google ya no es válida: vuelve a iniciar sesión';

  @override
  String get googleErrorConfiguration =>
      'El inicio de sesión con Google no está configurado correctamente en el servidor';

  @override
  String get googleErrorIdentity => 'Google no pudo verificar tu identidad';

  @override
  String get googleErrorLinkRequired =>
      'Esta dirección ya existe: vincula Google desde el perfil web antes de usarlo aquí';

  @override
  String get googleErrorRegistrationRequired =>
      'Primero crea la cuenta en el sitio web y después inicia sesión desde esta aplicación';

  @override
  String get googleErrorInactive => 'La cuenta de CercaPosta no está activa';

  @override
  String get googleErrorInvalid =>
      'El inicio de sesión con Google no es válido o ha caducado: inténtalo de nuevo';

  @override
  String get googleErrorDisabled =>
      'El inicio de sesión con Google no está habilitado en este servidor';

  @override
  String get googleErrorUnavailable =>
      'El inicio de sesión con Google no está disponible';

  @override
  String get appleErrorCancelled => 'Se canceló el inicio de sesión con Apple';

  @override
  String get appleErrorState =>
      'La sesión de Apple ya no es válida: vuelve a iniciar sesión';

  @override
  String get appleErrorIdentity => 'Apple no pudo verificar tu identidad';

  @override
  String get appleErrorLinkRequired =>
      'Esta dirección ya existe: vincula Apple desde el perfil web antes de usarlo aquí';

  @override
  String get appleErrorRegistrationRequired =>
      'Primero crea la cuenta en el sitio web y después inicia sesión desde esta aplicación';

  @override
  String get appleErrorInactive => 'La cuenta de CercaPosta no está activa';

  @override
  String get appleErrorInvalid =>
      'El inicio de sesión con Apple no es válido o ha caducado: inténtalo de nuevo';

  @override
  String get appleErrorDisabled =>
      'El inicio de sesión con Apple no está habilitado en este servidor';

  @override
  String get appleErrorUnavailable =>
      'El inicio de sesión con Apple no está disponible';

  @override
  String get settingsServer => 'Servidor';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsLanguageIt => 'Italiano';

  @override
  String get settingsLanguageEn => 'Inglés';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeAuto => 'Automático';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsRemoteImages => 'Imágenes en el correo';

  @override
  String get settingsRemoteImagesAlways => 'Mostrar siempre imágenes remotas';

  @override
  String get settingsRemoteImagesWarning =>
      'Es más cómodo, pero puede informar a los remitentes de que has abierto un correo. Para mayor privacidad, permite solo remitentes de confianza.';

  @override
  String get settingsOsNotifications => 'Notificaciones del sistema';

  @override
  String get settingsOsNotificationsHint =>
      'Muestra las nuevas notificaciones en el centro de notificaciones del teléfono. En Android se comprueban aproximadamente cada 15 minutos; en iOS, cuando lo permite el sistema.';

  @override
  String get settingsOsNotificationsDenied =>
      'Permiso denegado: habilita las notificaciones de CercaPosta en la configuración del sistema.';

  @override
  String get settingsBiometric => 'Inicio de sesión y desbloqueo con biometría';

  @override
  String get settingsBiometricEnablePrompt =>
      'Confirma tu contraseña para autorizar este dispositivo y después completa la verificación biométrica. La aplicación no conservará tu contraseña.';

  @override
  String get settingsSessions => 'Dispositivos y sesiones';

  @override
  String get passkeysTitle => 'Claves de acceso';

  @override
  String get passkeysSettingsHint => 'Inicia sesión sin escribir tu contraseña';

  @override
  String get passkeysDescription =>
      'Las claves de acceso usan el desbloqueo seguro de tu dispositivo, como la huella, el rostro o el PIN. La clave privada nunca sale del dispositivo ni del proveedor de claves de acceso.';

  @override
  String get passkeysAdd => 'Añadir una clave de acceso';

  @override
  String get passkeysEmpty => 'Aún no has registrado ninguna clave de acceso.';

  @override
  String get passkeysSynced => 'Sincronizada';

  @override
  String get passkeysDeviceBound => 'Solo este dispositivo';

  @override
  String passkeysCreated(String date) {
    return 'Creada el $date';
  }

  @override
  String passkeysLastUsed(String date) {
    return 'Último uso: $date';
  }

  @override
  String get passkeysRename => 'Cambiar nombre';

  @override
  String get passkeysRenameTitle => 'Cambiar nombre de la clave de acceso';

  @override
  String get passkeysName => 'Nombre de la clave de acceso';

  @override
  String get passkeysRemoveTitle => 'Eliminar clave de acceso';

  @override
  String passkeysRemoveConfirm(String name) {
    return '¿Eliminar la clave de acceso «$name»? Ya no podrás usarla para iniciar sesión.';
  }

  @override
  String get passkeysPasswordStays =>
      'Las claves de acceso son opcionales: la contraseña y el inicio de sesión con Google siguen disponibles. En un archivo cifrado, un dispositivo nuevo o que no sea de confianza sigue necesitando la contraseña o el kit de recuperación para desbloquear el contenido.';

  @override
  String get passkeyErrorCancelled => 'Operación cancelada';

  @override
  String get passkeyErrorNoCredential =>
      'No hay ninguna clave de acceso de CercaPosta disponible en este dispositivo';

  @override
  String get passkeyErrorDomainNotAssociated =>
      'Este servidor aún no está asociado correctamente con la aplicación para las claves de acceso';

  @override
  String get passkeyErrorUnavailable =>
      'Las claves de acceso no están disponibles en este dispositivo. Puedes seguir iniciando sesión con tu contraseña.';

  @override
  String get passkeyErrorTimeout =>
      'La solicitud de clave de acceso superó el tiempo de espera. Inténtalo de nuevo.';

  @override
  String get passkeyErrorInvalid =>
      'La clave de acceso no se reconoce o ya no es válida';

  @override
  String get passkeyErrorNotConfigured =>
      'Las claves de acceso aún no están configuradas en este servidor';

  @override
  String get passkeyErrorAlreadyRegistered =>
      'Esta clave de acceso ya está registrada';

  @override
  String get settingsLogout => 'Cerrar sesión';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String settingsVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get sessionsTitle => 'Dispositivos y sesiones';

  @override
  String get sessionsCurrent => 'Este dispositivo';

  @override
  String get sessionsRevoke => 'Desconectar';

  @override
  String get sessionsRevokeAll => 'Desconectar todos';

  @override
  String get sessionsRevokeAllConfirm =>
      '¿Desconectar todos los dispositivos? Tendrás que volver a iniciar sesión en cada uno.';

  @override
  String get sessionsEmpty => 'No hay sesiones activas.';

  @override
  String sessionsLastSeen(String when) {
    return 'Última actividad: $when';
  }

  @override
  String sessionsCreated(String when) {
    return 'Activa desde: $when';
  }

  @override
  String sessionsIp(String ip) {
    return 'Dirección IP: $ip';
  }

  @override
  String get serverHttpsRequired =>
      'El servidor debe usar HTTPS. No se permiten direcciones http:// sin cifrar.';

  @override
  String get serverRemoveSaved => 'Eliminar de los servidores guardados';

  @override
  String get searchClear => 'Limpiar búsqueda';

  @override
  String get searchLoadMoreError => 'No se pudo cargar. Toca para reintentar.';

  @override
  String get filterSize => 'Tamaño';

  @override
  String get filterSizeGreater => 'mayor que';

  @override
  String get filterSizeLess => 'menor que';

  @override
  String get filterAccount => 'Cuenta (ID del origen)';

  @override
  String get emailBcc => 'CCO';

  @override
  String get emailLinkError => 'No se pudo abrir el enlace';

  @override
  String get attachmentShare => 'Compartir';

  @override
  String get attachmentShareError => 'No se pudo compartir el adjunto';

  @override
  String get chatStop => 'Detener';

  @override
  String get chatDelete => 'Eliminar conversación';

  @override
  String get chatDeleteConfirm => '¿Eliminar esta conversación?';

  @override
  String get chatRename => 'Cambiar nombre';

  @override
  String get chatRenameTitle => 'Cambiar nombre de la conversación';

  @override
  String get chatStatusError => 'No se pudo comprobar el estado del chat';

  @override
  String get settingsChangeServer => 'Cambiar de servidor';

  @override
  String get settingsChangeServerConfirm =>
      '¿Cambiar de servidor? Se cerrará la sesión en el actual.';

  @override
  String errorWeakPasswordDetail(String requirements) {
    return 'La contraseña debe incluir: $requirements';
  }

  @override
  String get pwMinLength => 'una longitud mayor';

  @override
  String get pwRequireLower => 'una letra minúscula';

  @override
  String get pwRequireUpper => 'una letra mayúscula';

  @override
  String get pwRequireDigit => 'un dígito';

  @override
  String get pwRequireSymbol => 'un símbolo';

  @override
  String get pwMinCharClasses => 'más tipos de caracteres';

  @override
  String get updateAvailable =>
      'Hay una versión más reciente de la aplicación.';

  @override
  String get updateRequiredTitle => 'Actualización necesaria';

  @override
  String updateRequiredBody(String current) {
    return 'El servidor ya no admite esta versión de la aplicación ($current). Actualiza a la última versión para seguir usando CercaPosta.';
  }

  @override
  String get updateRequiredButton => 'Actualizar ahora';

  @override
  String get updateStoreError =>
      'No se pudo abrir la tienda. Actualiza manualmente desde App Store o Play Store.';

  @override
  String get emailPecSection => 'Sobre de transporte PEC';

  @override
  String get emailPecTransportFrom => 'Transportado por';

  @override
  String get emailPecTransportSubject => 'Asunto del sobre';

  @override
  String get emailPecTransportDate => 'Fecha de transporte';

  @override
  String get emailPecDaticert => 'Certificación (daticert.xml) presente';

  @override
  String get settingsStorage => 'Almacenamiento';

  @override
  String settingsStorageValue(String used, String quota, String percent) {
    return '$used de $quota ($percent%)';
  }

  @override
  String settingsStorageUnlimited(String used) {
    return '$used · sin límite';
  }

  @override
  String get errorInvalidCredentials => 'Credenciales no válidas';

  @override
  String get errorAccountBanned =>
      'Cuenta bloqueada temporalmente por demasiados intentos';

  @override
  String get errorInvalidToken =>
      'La sesión ha caducado. Vuelve a iniciar sesión';

  @override
  String get errorInvalidRefresh =>
      'La sesión no es válida. Vuelve a iniciar sesión';

  @override
  String get errorForbidden => 'Operación no permitida';

  @override
  String get errorFeatureNotInPlan =>
      'Esta función no está incluida en el plan actual';

  @override
  String get errorAdminNotOnMobile =>
      'Las funciones de administración no están disponibles en dispositivos móviles';

  @override
  String get errorTotpInvalidCode => 'Código no válido';

  @override
  String get errorTotpExpired =>
      'El código ha caducado. Vuelve a iniciar sesión';

  @override
  String get errorDekLocked =>
      'Archivo bloqueado. Desbloquéalo con tu contraseña.';

  @override
  String get errorRecoveryFailed =>
      'La recuperación falló. Revisa tu código de recuperación.';

  @override
  String get errorWeakPassword =>
      'La contraseña no cumple los requisitos de seguridad';

  @override
  String get errorTotpSetupRequired =>
      'Tu cuenta requiere verificación en dos pasos: configúrala desde la web antes de iniciar sesión en la aplicación';

  @override
  String get errorChatNotConfigured => 'Chat de IA no configurado';

  @override
  String errorChatLlmError(String detail) {
    return 'Error del modelo de IA: $detail';
  }

  @override
  String get errorNotFound => 'No encontrado';

  @override
  String get errorPreviewUnsupported =>
      'La vista previa no está disponible para este formato';

  @override
  String get errorPreviewFailed => 'No se pudo generar la vista previa';

  @override
  String get errorRawMissing => 'El archivo ya no está disponible';

  @override
  String get errorValidation => 'Datos no válidos';

  @override
  String get errorNetwork => 'Error de red. Comprueba tu conexión.';

  @override
  String get errorGeneric => 'Error inesperado';

  @override
  String get errorFollowupNotRemindable =>
      'Ya no se puede enviar un recordatorio para este seguimiento.';

  @override
  String get errorFollowupNotConfigured =>
      'El modelo de análisis no está configurado en este servidor.';

  @override
  String get errorFollowupDraftFailed =>
      'No se pudo generar el recordatorio. Inténtalo de nuevo.';

  @override
  String get errorFollowupSendNoSource =>
      'No hay ninguna cuenta de origen que pueda enviar este mensaje.';

  @override
  String get errorSendConsentRequired =>
      'Debes volver a autorizar la cuenta de Microsoft 365 para enviar desde la aplicación web.';

  @override
  String get errorMailAuthFailed =>
      'Falló la autenticación en la cuenta de correo.';

  @override
  String get errorMailSendFailed => 'El envío falló. Inténtalo más tarde.';

  @override
  String get navFollowups => 'En espera';

  @override
  String get followupsTitle => 'En espera';

  @override
  String get followupsTabTheirTurn => 'En espera de respuesta';

  @override
  String get followupsTabMyTurn => 'Por responder';

  @override
  String get followupsEmpty => 'No hay seguimientos abiertos.';

  @override
  String get followupsRecentlyClosed => 'Cerrados recientemente';

  @override
  String get followupsLoadMore => 'Cargar más';

  @override
  String get followupsDisabledTitle => 'Función no habilitada';

  @override
  String get followupsDisabledBody =>
      'El seguimiento de respuestas se habilita desde tu perfil en la aplicación web.';

  @override
  String get followupsUnavailableTitle => 'Requiere un servidor actualizado';

  @override
  String get followupsUnavailableBody =>
      'Este servidor aún no ofrece la gestión del seguimiento de respuestas.';

  @override
  String get followupsPausedEndpoint =>
      'Análisis en pausa: el endpoint de IA no responde. El archivo sigue sincronizándose.';

  @override
  String get followupsPausedCap =>
      'Análisis en pausa: se alcanzó el límite diario.';

  @override
  String get followupsPausedBilling =>
      'Análisis en pausa: se alcanzó el límite del plan de IA.';

  @override
  String get followupsActionOpen => 'Abrir conversación';

  @override
  String get followupsActionReminder => 'Preparar recordatorio';

  @override
  String get followupsActionDone => 'Hecho';

  @override
  String get followupsActionSnooze1 => 'Aplazar 1 día';

  @override
  String get followupsActionSnooze3 => 'Aplazar 3 días';

  @override
  String get followupsActionDismiss => 'Descartar';

  @override
  String get followupsActionError => 'La acción falló';

  @override
  String get followupsChipAnswered => 'Respondido';

  @override
  String get followupsChipDismissed => 'Descartado';

  @override
  String followupsChipSnoozed(String date) {
    return 'Aplazado hasta el $date';
  }

  @override
  String followupsChipReminded(String date) {
    return 'Recordatorio enviado el $date';
  }

  @override
  String followupsChipRemindedMany(String date, int count) {
    return 'Recordatorio enviado el $date ×$count';
  }

  @override
  String followupsChipOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días de retraso',
      one: '1 día de retraso',
    );
    return '$_temp0';
  }

  @override
  String get followupsChipDueToday => 'Vence hoy';

  @override
  String get followupsChipDueTomorrow => 'Vence mañana';

  @override
  String followupsChipDueOn(String date) {
    return 'Vence el $date';
  }

  @override
  String get reminderTitle => 'Preparar recordatorio';

  @override
  String get reminderGenerating => 'Generando borrador…';

  @override
  String get reminderFailed => 'No se pudo generar el borrador.';

  @override
  String get reminderSubject => 'Asunto';

  @override
  String get reminderMessage => 'Mensaje';

  @override
  String get reminderRegister => 'Tratamiento';

  @override
  String get reminderRegisterAuto => 'Automático';

  @override
  String get reminderRegisterTu => 'Informal';

  @override
  String get reminderRegisterLei => 'Formal';

  @override
  String reminderRegisterUsed(String register, String source) {
    return 'Tratamiento: $register ($source)';
  }

  @override
  String get reminderRegisterSourceManual => 'elegido';

  @override
  String get reminderRegisterSourceContact => 'guardado para el contacto';

  @override
  String get reminderRegisterSourceDetected =>
      'detectado a partir de tu estilo';

  @override
  String get reminderRegisterSourceDefault => 'predeterminado';

  @override
  String get reminderRememberContact => 'Recordar para el contacto';

  @override
  String get reminderRemembered => 'Tratamiento guardado para este contacto';

  @override
  String get reminderLanguage => 'Idioma';

  @override
  String get reminderLanguageAuto => 'Automático';

  @override
  String get reminderInstructionsHint =>
      'Instrucciones para regenerar (opcional)';

  @override
  String get reminderRegenerate => 'Regenerar';

  @override
  String get reminderExpand => 'Pantalla completa';

  @override
  String get reminderInstructions => 'Instrucciones';

  @override
  String get reminderIncludeOriginal => 'Citar el correo original al final';

  @override
  String get reminderAppendedNote =>
      'La firma, el aviso de IA y, si corresponde, la cita del correo original se añaden automáticamente.';

  @override
  String reminderSendFromNote(String from) {
    return 'Se enviará desde tu cuenta $from';
  }

  @override
  String get reminderPreview => 'Vista previa del correo';

  @override
  String get reminderPreviewTitle => 'Vista previa del correo';

  @override
  String get reminderSendNow => 'Enviar desde CercaPosta';

  @override
  String reminderSent(String from) {
    return 'Recordatorio enviado desde $from';
  }

  @override
  String notifFollowupNoReplyTitle(String name) {
    return '$name no ha respondido';
  }

  @override
  String notifFollowupNoReplyBody(String summary, int days) {
    return '«$summary» — sin respuesta desde hace $days días.';
  }

  @override
  String notifFollowupReplyDueTitle(String name) {
    return 'Deberías responder a $name';
  }

  @override
  String notifFollowupReplyDueBody(String summary, int days) {
    return '«$summary» — el plazo venció hace $days días.';
  }

  @override
  String get notifChannelName => 'Notificaciones';

  @override
  String notifSummaryTitle(int count) {
    return '$count notificaciones nuevas';
  }

  @override
  String get notifSummaryBody => 'Abre CercaPosta para verlas todas.';

  @override
  String get notifFollowupDueSoonTitle => 'Se acerca el vencimiento';

  @override
  String notifFollowupDueSoonBody(String summary, String name, String date) {
    return '«$summary» — $name: vence el $date.';
  }

  @override
  String notifFollowupReminderSentTitle(String name) {
    return 'Recordatorio enviado a $name';
  }

  @override
  String notifFollowupReminderSentBody(String summary) {
    return '«$summary» — se ha enviado el recordatorio automático.';
  }

  @override
  String get notifFollowupDigestTitle =>
      'Resumen del seguimiento de respuestas';

  @override
  String notifFollowupDigestBody(int overdue, int dueToday, int waitingMe) {
    return '$overdue vencidos · $dueToday vencen hoy · $waitingMe respuestas pendientes de enviar.';
  }

  @override
  String get notifOpenConversation => 'Abrir conversación';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get actionCopied => 'Copiado al portapapeles';

  @override
  String get emailHeadersTitle => 'Encabezados del mensaje';

  @override
  String get emailHeadersEmpty => 'No hay encabezados disponibles';

  @override
  String get followupMarkTitle => 'Marcar como pendiente de respuesta';

  @override
  String get followupMarkTheirTurn => 'Estoy esperando una respuesta';

  @override
  String get followupMarkTheirTurnHint =>
      'He escrito y estoy esperando que respondan';

  @override
  String get followupMarkMyTurn => 'Debo responder';

  @override
  String get followupMarkMyTurnHint => 'Me han escrito y me toca responder';

  @override
  String get followupMarkDue => 'Plazo (opcional)';

  @override
  String get followupMarkPickDue => 'Elegir una fecha';

  @override
  String get followupMarkConfirm => 'Crear';

  @override
  String get followupMarkCreated => 'Marcado como pendiente de respuesta';

  @override
  String get errorFollowupAlreadyActive =>
      'Ya hay un seguimiento abierto en esta conversación.';

  @override
  String get errorFollowupNoCounterpart =>
      'No se puede determinar quién debe responder: prueba la otra dirección.';

  @override
  String get memoryTitle => 'Memoria del chat';

  @override
  String get memorySettingsHint => 'Lo que el asistente ha aprendido sobre ti';

  @override
  String get memoryIntro =>
      'Esto es todo lo que el asistente ha aprendido sobre ti: cómo llamas a las personas, cómo prefieres los listados y qué datos da por sabidos. Puedes pausar u olvidar cualquier elemento, y no se aprende nada sin avisarte. Para añadir un recuerdo, dilo en el chat: «recuerda que…».';

  @override
  String get memoryPolicyLearn => 'Aprender de mis conversaciones';

  @override
  String get memoryPolicyLearnHint =>
      'Cuando está activado, el asistente propone lo que observa mientras trabajan juntos: te avisa cada vez y puedes deshacerlo. Si lo desactivas, solo se conservan los recuerdos que escribas tú.';

  @override
  String get memoryPolicyEnabled => 'Usar la memoria en las respuestas';

  @override
  String get memoryPolicyEnabledHint =>
      'Desactivar esta opción conserva todos los recuerdos, pero deja de aplicarlos: es una pausa, no una eliminación.';

  @override
  String memoryAnnounceAlias(String key, String value) {
    return 'He aprendido que para ti «$key» significa $value.';
  }

  @override
  String memoryAnnounceGeneric(String key, String value) {
    return 'He aprendido: $key → $value.';
  }

  @override
  String memoryAnnounceTrial(String what) {
    return '$what Por ahora lo mantengo en prueba: todavía no lo uso.';
  }

  @override
  String get memoryAnnounceUndo => 'Deshacer';

  @override
  String get memoryAnnounceUndone => 'Deshecho: no lo he conservado.';

  @override
  String get memoryAnnounceRejected => 'De acuerdo, no volveré a proponerlo.';

  @override
  String memoryAppliedNote(String list) {
    return 'De la memoria: $list';
  }

  @override
  String get memoryListEmpty =>
      'Aún no hay nada en la memoria. Puedes decirlo en el chat: «recuerda que…».';

  @override
  String get memoryListEmptyFiltered => 'No hay recuerdos en este estado.';

  @override
  String get memoryFilterAll => 'Todos';

  @override
  String get memoryFilterActive => 'Activos';

  @override
  String get memoryFilterTrial => 'En prueba';

  @override
  String get memoryFilterRejected => 'Rechazados';

  @override
  String get memoryFilterDisabled => 'En pausa';

  @override
  String get memoryStatusActive => 'Activo';

  @override
  String get memoryStatusTrial => 'En prueba';

  @override
  String get memoryStatusRejected => 'Rechazado';

  @override
  String get memoryStatusDisabled => 'En pausa';

  @override
  String get memoryStatusTrialHint =>
      'aún lo estoy aprendiendo; todavía no lo uso';

  @override
  String get memoryStatusStaleHint =>
      'no se usa desde hace meses: páusalo si ya no lo necesitas';

  @override
  String get memoryKindAlias => 'Cómo llamas a las personas';

  @override
  String get memoryKindParam => 'Cómo quieres las búsquedas';

  @override
  String get memoryKindRender => 'Cómo quieres los listados';

  @override
  String get memoryKindFact => 'Datos que tener en cuenta';

  @override
  String get memoryKindShortcut => 'Preguntas frecuentes';

  @override
  String get memoryTriggerSearch => 'al buscar';

  @override
  String get memoryTriggerListing => 'en los listados';

  @override
  String get memoryTriggerContact => 'sobre contactos';

  @override
  String get memoryTriggerAlways => 'siempre';

  @override
  String get memorySourceExplicit => 'lo dijiste tú';

  @override
  String get memorySourceCorrection => 'a partir de una corrección tuya';

  @override
  String get memorySourceRecurrence => 'a partir de un hábito';

  @override
  String get memorySourceSuggested => 'propuesto por el archivo';

  @override
  String get memorySourceInferred => 'deducido de algo que escribiste';

  @override
  String memoryUsedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'usado $count veces',
      one: 'usado una vez',
    );
    return '$_temp0';
  }

  @override
  String get memoryEnable => 'Reanudar';

  @override
  String get memoryDisable => 'Pausar';

  @override
  String get memoryReject => 'No recordar esto nunca';

  @override
  String get memoryUnreject => 'He cambiado de opinión';

  @override
  String get memoryDelete => 'Eliminar';

  @override
  String memoryDeleteConfirm(String key) {
    return '¿Eliminar el recuerdo «$key»? Si prefieres que no vuelva a proponerse, usa «No recordar esto nunca».';
  }

  @override
  String get memorySuggestionsTitle => 'Alias sugeridos por tu archivo';

  @override
  String get memorySuggestionsHint =>
      'Nombres que en tu archivo solo pueden referirse a una persona. Si los aceptas, al mencionarlos en el chat se buscará directamente su dirección.';

  @override
  String get memorySuggestionsAccept => 'Aceptar';

  @override
  String memorySuggestionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count correos',
      one: '1 correo',
    );
    return '$_temp0';
  }

  @override
  String get diagnosticsTitle => 'Diagnóstico';

  @override
  String get diagnosticsIntro =>
      'Comprueba si realmente se puede buscar en todo lo importado. Si falta algo, verás el motivo y, cuando corresponda, qué puedes hacer.';

  @override
  String get diagnosticsStatusOk =>
      'Todo correcto: el archivo está completo y se puede buscar en él.';

  @override
  String get diagnosticsStatusWorking =>
      'El trabajo sigue en curso: aún no se puede buscar en parte del archivo. No tienes que hacer nada.';

  @override
  String get diagnosticsStatusAttention =>
      'Hay algo que conviene revisar a continuación.';

  @override
  String get diagnosticsMessages => 'Mensajes en la búsqueda con IA';

  @override
  String get diagnosticsAttachments => 'Texto leído dentro de los adjuntos';

  @override
  String diagnosticsOf(String done, String total) {
    return '$done de $total';
  }

  @override
  String diagnosticsAttachmentsPending(String n) {
    return '$n adjuntos en cola';
  }

  @override
  String diagnosticsMessagesPending(String n) {
    return '$n mensajes en cola';
  }

  @override
  String get diagnosticsEmbeddingOff => 'Búsqueda con IA desactivada';

  @override
  String get diagnosticsEmbeddingPaused => 'en pausa: límites del plan de IA';

  @override
  String get diagnosticsEmbeddingActive => 'cola en ejecución';

  @override
  String diagnosticsEmbeddingLastError(String when, String detail) {
    return 'último error ($when): $detail';
  }

  @override
  String diagnosticsRetryAll(String n) {
    return 'Reintentar $n adjuntos';
  }

  @override
  String get diagnosticsRetryHint =>
      'Se detuvieron por un fallo temporal: otro intento puede funcionar.';

  @override
  String diagnosticsRetryExhaustedHint(String n) {
    return '$n de estos ya agotaron los cinco intentos automáticos: tiene sentido reintentar si ya se ha resuelto lo que los detuvo.';
  }

  @override
  String diagnosticsReasonsTitle(String n) {
    return 'Por qué $n adjuntos no tienen texto';
  }

  @override
  String diagnosticsExpectedTitle(String n) {
    return '$n adjuntos no eran documentos que leer';
  }

  @override
  String diagnosticsEmbedReasonsTitle(String n) {
    return 'Por qué $n mensajes no entraron en la búsqueda con IA';
  }

  @override
  String get diagnosticsActionRetry => 'Reintentar';

  @override
  String get diagnosticsActionAskAdmin => 'Requiere al administrador';

  @override
  String get diagnosticsActionNone => 'No hay nada que hacer';

  @override
  String get diagnosticsReasonTikaHttpError =>
      'El lector de documentos no respondía';

  @override
  String get diagnosticsReasonTikaTimeout => 'El documento tardó demasiado';

  @override
  String get diagnosticsReasonTikaServerError =>
      'El lector de documentos devolvió un error';

  @override
  String get diagnosticsReasonTikaBusy =>
      'El lector de documentos está ocupado temporalmente';

  @override
  String get diagnosticsReasonTikaPartial =>
      'Solo se recuperó parte del texto del documento';

  @override
  String get diagnosticsReasonTikaInvalidLimits =>
      'Los límites de extracción no son válidos: contacta con el administrador';

  @override
  String get diagnosticsReasonTikaRejected =>
      'El lector de documentos rechazó el archivo';

  @override
  String get diagnosticsReasonTikaUnsupported =>
      'Tipo de archivo que no puedo leer';

  @override
  String get diagnosticsReasonExtractBacklogError =>
      'Error inesperado durante la lectura';

  @override
  String get diagnosticsReasonUnmatchedPart =>
      'No se encontró el adjunto dentro del mensaje';

  @override
  String get diagnosticsReasonOverSizeLimit =>
      'Supera el límite de tamaño permitido';

  @override
  String get diagnosticsReasonEmpty => 'Archivo vacío';

  @override
  String get diagnosticsReasonSignatureFile =>
      'Firma digital, no es un documento';

  @override
  String get diagnosticsReasonInlineImage =>
      'Imagen incrustada en el mensaje (logotipo, firma)';

  @override
  String get diagnosticsReasonUnknown => 'Causa no registrada';

  @override
  String get diagnosticsSettingsHint =>
      'Comprueba si se puede buscar en todo lo importado y qué falta';

  @override
  String get billingTitle => 'Plan y pagos';

  @override
  String get billingSettingsHint =>
      'Plan actual, renovación y cambios programados';

  @override
  String get billingCurrentPlan => 'Plan actual';

  @override
  String get billingNoPlan => 'No hay ningún plan activo.';

  @override
  String get billingStatus => 'Estado';

  @override
  String get billingPaymentMethod => 'Método de pago';

  @override
  String get billingRecurringPrice => 'Precio recurrente';

  @override
  String get billingPeriodEnd => 'Fin del período';

  @override
  String get billingPlanValidity => 'Vigencia del plan';

  @override
  String get billingNoExpiration => 'Sin vencimiento';

  @override
  String get billingPeriodicity => 'Frecuencia de facturación';

  @override
  String get billingIntervalMonthly => 'Mensual';

  @override
  String get billingIntervalAnnual => 'Anual';

  @override
  String get billingNextRenewal => 'Próxima renovación';

  @override
  String get billingNextRenewalAmount => 'Importe de la próxima renovación';

  @override
  String get billingDateUnavailable => 'La fecha aún no está disponible';

  @override
  String get billingGraceUntil => 'Período de gracia hasta';

  @override
  String get billingPendingChanges => 'Cambios de plan';

  @override
  String get billingEffectiveAt => 'Fecha de entrada en vigor';

  @override
  String get billingAmountDue => 'Importe previsto';

  @override
  String get billingManageInBrowser => 'Gestionar el plan y los pagos';

  @override
  String get billingExternalCheckoutHint =>
      'Para proteger tu pago, la compra, los reintentos de pago y las cancelaciones se completan en el área segura de CercaPosta en tu navegador.';

  @override
  String get billingStatusActive => 'Activo';

  @override
  String get billingStatusFree => 'Gratuito';

  @override
  String get billingStatusPastDue => 'Pago vencido';

  @override
  String get billingStatusSuspended => 'Suspendido';

  @override
  String get billingStatusCanceled => 'Cancelado';

  @override
  String get billingProviderManual => 'Pago manual';

  @override
  String get billingChangePendingAcceptance => 'Pendiente de tu aceptación';

  @override
  String get billingChangePendingPayment => 'Pendiente de pago';

  @override
  String get billingChangeScheduled => 'Programado';

  @override
  String get billingChangeProcessing => 'En proceso';

  @override
  String get billingChangePaymentGrace => 'Pago fallido · período de gracia';

  @override
  String get billingChangeCanceling => 'Cancelación en curso';

  @override
  String get notifPlanChangeProposalTitle =>
      'Tienes una propuesta de cambio de plan';

  @override
  String get notifPlanChangeProposalBody =>
      'Abre Plan y pagos para revisar el precio, el crédito y la fecha de entrada en vigor.';

  @override
  String get notifPlanChangeProposalExpiringTitle =>
      'La propuesta está a punto de caducar';

  @override
  String notifPlanChangeProposalExpiringBody(String date) {
    return 'Revísala antes del $date.';
  }

  @override
  String get notifPlanChangeExpiredTitle => 'El cambio de plan ha caducado';

  @override
  String get notifPlanChangeExpiredBody =>
      'El cambio no se aplicó y se mantuvo el plan anterior.';

  @override
  String get notifPlanChangeScheduledTitle =>
      'El cambio de plan está programado';

  @override
  String notifPlanChangeScheduledBody(String date) {
    return 'El cambio se aplicará el $date; tu plan actual seguirá activo hasta entonces.';
  }

  @override
  String get notifPlanChangeAppliedTitle => 'Tu nuevo plan está activo';

  @override
  String get notifPlanChangeAppliedBody =>
      'Las nuevas cuotas y funciones ya están disponibles.';

  @override
  String get notifPlanChangeCanceledTitle => 'Se canceló el cambio de plan';

  @override
  String get notifPlanChangeCanceledBody =>
      'Tu plan actual se mantiene sin cambios.';

  @override
  String get notifPlanChangePaymentFailedTitle => 'El pago falló';

  @override
  String notifPlanChangePaymentFailedBody(String date) {
    return 'Tu plan anterior sigue activo. Reintenta el pago antes del $date.';
  }

  @override
  String get notifPlanChangeRetryTitle => 'Puedes reintentar el pago';

  @override
  String get notifPlanChangeRetryBody =>
      'Abre Plan y pagos para completar el nuevo intento.';

  @override
  String get notifPlanChangeGraceExpiringTitle =>
      'El período de gracia está a punto de finalizar';

  @override
  String notifPlanChangeGraceExpiringBody(String date) {
    return 'Completa el pago antes del $date.';
  }

  @override
  String get notifPlanChangeGraceExpiredTitle =>
      'El período de gracia ha finalizado';

  @override
  String get notifPlanChangeGraceExpiredBody =>
      'El cambio no se aplicó porque no se completó el pago.';

  @override
  String get notifPlanChangeActionRequiredTitle =>
      'El cambio de plan requiere asistencia';

  @override
  String get notifPlanChangeActionRequiredBody =>
      'Revisa Plan y pagos o contacta con soporte.';

  @override
  String get passkeyUnsupportedServer =>
      'Las claves de acceso no están disponibles para este servidor en esta versión de la aplicación. Usa contraseña, Google o Apple; puedes gestionar las claves de acceso en el sitio web del servidor.';

  @override
  String get searchVoiceLocalUnavailable =>
      'El reconocimiento en el dispositivo no está disponible para este idioma o dispositivo. Usa el teclado; Android requiere Android 12 o posterior y un reconocedor local instalado.';

  @override
  String get deliveryHistory => 'Resultados de los envíos';

  @override
  String get deliveryReference => 'Referencia del envío';

  @override
  String get deliverySending => 'Enviando';

  @override
  String get deliverySent => 'Aceptado por el servicio de correo';

  @override
  String get deliveryFailed => 'No enviado';

  @override
  String get deliveryUnknown => 'Resultado pendiente de verificar';

  @override
  String get deliveryChecked =>
      'He comprobado el resultado con el servicio de correo y he confirmado que el intento ya no está en curso. Si el proceso estaba bloqueado, he solicitado que se detuviera.';

  @override
  String get deliveryConfirmSent => 'Confirmar aceptación';

  @override
  String get deliveryConfirmFailed => 'Confirmar que no se envió';

  @override
  String get deliveryResolved =>
      'Resultado registrado. No se envió ningún mensaje nuevo.';

  @override
  String get deliveryEmpty => 'No hay intentos de envío registrados.';

  @override
  String get errorDeliveryUnknown =>
      'El servicio de correo puede haber aceptado el mensaje. Consulta Resultados de los envíos y verifica el resultado con el proveedor antes de reintentar.';

  @override
  String get errorDeliverySending =>
      'Ya hay un envío en curso para esta respuesta pendiente. No lo reintentes.';

  @override
  String get errorDeliveryConflict =>
      'Esta solicitud ya se ha procesado o tiene un contenido diferente. Consulta Resultados de los envíos.';

  @override
  String get errorDeliveryCheckRequired =>
      'Verifica el resultado con el servicio de correo antes de confirmarlo.';

  @override
  String get errorMailNotAccepted =>
      'El intento falló antes de que el servicio de correo lo aceptara. Corrige el problema y reintenta.';

  @override
  String get errorMailDeliveryUnknown =>
      'El resultado del envío es incierto. Compruébalo con el servicio de correo antes de reintentar.';

  @override
  String get biometricErrorCancelled =>
      'Se canceló la verificación biométrica. Puedes iniciar sesión con tu contraseña.';

  @override
  String get biometricErrorUnavailable =>
      'El almacenamiento biométrico no está disponible. Usa tu contraseña; si has cambiado las huellas o Face ID, vuelve a habilitar la biometría en la configuración.';

  @override
  String get biometricErrorReenroll =>
      'La autorización de este dispositivo ha caducado o ya no es válida. Inicia sesión manualmente y vuelve a habilitar la biometría en la configuración.';

  @override
  String get errorReauthenticationRequired =>
      'Por seguridad, cierra la sesión y vuelve a iniciarla con tu método habitual; después habilita la biometría antes de que transcurran 5 minutos.';

  @override
  String get aiReportAction => 'Reportar respuesta';

  @override
  String get aiReportTitle => 'Reportar respuesta de IA';

  @override
  String get aiReportIntro =>
      'La respuesta y tu comentario se enviarán de forma segura a los administradores para su revisión.';

  @override
  String get aiReportReason => 'Motivo';

  @override
  String get aiReportReasonMisleading => 'Engañosa o incorrecta';

  @override
  String get aiReportReasonHarmful => 'Perjudicial';

  @override
  String get aiReportReasonIllegal => 'Contenido ilegal';

  @override
  String get aiReportReasonPrivacy => 'Problema de privacidad';

  @override
  String get aiReportReasonOther => 'Otro';

  @override
  String get aiReportComment => 'Comentario opcional';

  @override
  String get aiReportCommentHint => 'Explica qué problema tiene la respuesta';

  @override
  String get aiReportSend => 'Enviar reporte';

  @override
  String get aiReportSent => 'Reporte enviado';

  @override
  String get aiReportAlreadySent => 'Esta respuesta ya se había reportado';

  @override
  String get tagsTitle => 'Etiquetas';

  @override
  String get tagsAssignHint =>
      'Asigna etiquetas a este mensaje o gestiona las etiquetas disponibles';

  @override
  String get tagsManageMessage => 'Gestionar etiquetas';

  @override
  String get tagsEmpty => 'Aún no has creado ninguna etiqueta.';

  @override
  String get tagsCreate => 'Crear etiqueta';

  @override
  String get tagsCreateTitle => 'Nueva etiqueta';

  @override
  String get tagsEdit => 'Editar';

  @override
  String get tagsEditTitle => 'Editar etiqueta';

  @override
  String get tagsDelete => 'Eliminar';

  @override
  String get tagsDeleteTitle => 'Eliminar etiqueta';

  @override
  String tagsDeleteConfirm(String name) {
    return '¿Eliminar la etiqueta «$name» de todo el archivo?';
  }

  @override
  String get tagsName => 'Nombre';

  @override
  String get actionDone => 'Hecho';

  @override
  String get errorTagNameRequired => 'Introduce un nombre para la etiqueta.';

  @override
  String get errorTagNameTaken => 'Ya existe una etiqueta con este nombre.';

  @override
  String get errorTagInvalidColor => 'El color seleccionado no es válido.';

  @override
  String get errorAiReportMessageNotFound =>
      'Esta respuesta ya no está disponible para reportarla.';

  @override
  String get errorAiReportAssistantOnly =>
      'Solo se pueden reportar respuestas del asistente.';

  @override
  String get settingsLanguageUiHint =>
      'Esta elección solo se aplica a la interfaz de este dispositivo.';

  @override
  String get settingsProfileLanguage =>
      'Idioma de los correos, los recibos y las respuestas de IA';

  @override
  String get settingsProfileLanguageHint =>
      'Se usa para correos, recibos y respuestas de IA. Los recibos de un espacio compartido siguen la preferencia de su titular. El idioma de la interfaz y los formatos de fecha y números son independientes. Los recibos ya emitidos no cambian.';

  @override
  String get searchVoiceChooseLanguage => 'Idioma y variante del dictado local';

  @override
  String get searchVoiceHint =>
      'Dictado local. Mantén pulsado para elegir el idioma y la variante.';
}
