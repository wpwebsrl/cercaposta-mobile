# CercaPosta mobile — regole di sviluppo

App **Flutter** (Android + iOS, bundle `it.cercaposta.app`) di **sola interrogazione** per
CercaPosta, l'archivio email intelligente di wpweb S.R.L. Il **server è un repo privato
separato** (in locale: `D:\sviluppo\cercaposta`): questo repo contiene SOLO il client.

**Perché questo repo è PUBBLICO**: i repo pubblici hanno minuti GitHub Actions **gratuiti e
illimitati** sui runner standard, macOS compreso → build e release iOS senza vincoli di costo.
Estratto dal monorepo privato il 9 lug 2026 con storia fresca (commit iniziale `f25e155`);
la storia precedente vive nel monorepo. LICENSE proprietaria (source-available): il codice è
visibile ma non riutilizzabile.

## Regole permanenti

1. **Repo pubblico — igiene assoluta**: MAI committare segreti o materiale di firma.
   In particolare non devono MAI apparire: `android/key.properties`, `*.jks`/`*.keystore`,
   `AuthKey_*.p8`, provisioning profile, `google-services.json`, `.env`, URL di server
   interni, email personali. La firma vive SOLO nei GitHub Secrets (vedi «Release»).
   Prima di committare file di configurazione nuovi: ricontrolla che non contengano valori.
2. **i18n OVUNQUE**: nessuna stringa visibile all'utente hardcoded. Cataloghi ARB in
   `assets/l10n/app_it.arb` + `app_en.arb` — ogni modifica UI aggiorna SEMPRE entrambi
   (`flutter gen-l10n` rigenera `lib/core/i18n/`). Il backend restituisce codici errore
   macchina (`error.code`): si traducono in `lib/core/api/error_messages.dart`.
3. **Client di sola interrogazione**: niente funzioni di invio/modifica email, niente
   funzioni admin (il claim `client` = `ios`/`android` le blocca anche lato server).
4. **Codice**: Dart con `flutter analyze` pulito e `dart format` (la CI fallisce altrimenti);
   identificatori e commenti in inglese; stringhe utente SOLO negli ARB.
5. **UI densa e curata**, coerente light/dark, come il web (densità, tipografia 13-14px).
6. **Git**: commit liberi, ma **chiedere conferma prima di ogni `git push`** (parte la CI).
   Push = dual-push automatico: `origin` scrive sia sul mirror privato OneDev sia su GitHub
   (due `pushurl` configurati in locale). Il remote `github` esiste per la CLI `gh`.

## Comandi

- Setup: `flutter pub get`
- Run (emulatore Android di sviluppo: AVD `cercaposta_pixel`): `flutter run`
- Test: `flutter test` · Analisi: `flutter analyze` · Format: `dart format .`
- Rigenerare i18n dopo aver toccato gli ARB: `flutter gen-l10n`
- **Guardia version-floor** (vedi sotto): `python tool/check_version_floor.py`
  (trova da solo il repo server se è il sibling `../cercaposta`; altrimenti
  `CERCAPOSTA_COMPAT=<path a compat.py>`)

## Versioni, compatibilità col server, release

- **`version:` in `pubspec.yaml`** è il semver dell'app (`major.minor.patch`; il `+N` è
  ignorato: il build number lo assegna la CI). L'app lo invia come `app_version` a
  login/refresh e lo confronta con `/meta` (`lib/shared/models/meta.dart`).
- **Compatibilità a 2 livelli** (registro: `backend/app/core/compat.py` nel repo server;
  doc completa: `docs/aggiornamenti.md` del monorepo):
  - **auth-breaking** → il server risponde **426** a login/2FA/refresh → schermata
    `lib/features/login/update_required_screen.dart` (non chiudibile) → store;
  - **feature-breaking** → floor da `/meta` post-login → `home_shell.dart` +
    `update_check.dart` → stessa schermata.
- **PRIMA di ogni release**: `python tool/check_version_floor.py` col repo server
  disponibile (in CI il guard SALTA — il registro è privato — quindi il check è
  responsabilità locale). Se il server ha alzato i floor, bumpa `version:` prima.
- **Release** (manuale, da GitHub Actions → workflow `mobile` → Run workflow, oppure):
  ```bash
  gh workflow run mobile.yml --repo wpwebsrl/cercaposta-mobile -f platform=ios      # TestFlight
  gh workflow run mobile.yml --repo wpwebsrl/cercaposta-mobile -f platform=android  # AAB artefatto
  gh workflow run mobile.yml --repo wpwebsrl/cercaposta-mobile -f platform=both
  ```
  - **Build number = `run_number + 100`** (offset per continuità col monorepo, che era
    arrivato a build 20: TestFlight/Play rifiutano numeri già usati — NON rimuoverlo).
  - iOS: firma automatica + upload **TestFlight** via fastlane (`ios/fastlane/`).
  - Android: **AAB firmato** come artefatto della run → upload manuale su Play Console
    (+ artefatto `android-symbols-<N>` per de-offuscare i crash di quella build).
  - La CI inietta l'identità di build (`--dart-define=APP_BUILD`/`APP_BUILD_DATE`,
    mostrata nell'About). Nota: `STORE_URL_IOS` (link TestFlight per il bottone
    «Aggiorna» iOS) è un dart-define opzionale non ancora passato dalla CI.
- **Secrets richiesti** (Settings → Secrets → Actions; MAI valori nel codice):
  `ASC_KEY_ID`, `ASC_ISSUER_ID`, `APPLE_TEAM_ID`, `ASC_KEY_P8_BASE64`,
  `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_PROPERTIES`. Le PR da fork non li ricevono
  (default GitHub: non cambiarlo). Su push/PR girano solo job SENZA segreti
  (analyze+test Android e compilazione iOS unsigned).
- Stato store alla data dello split: iOS **1.0.0 (20)** su TestFlight, Android
  **1.0.0 (20)** AAB generato; prossime build CI ≈ 121+.

## Layout (punti d'ingresso)

- `lib/main.dart` → router `lib/core/router/app_router.dart` → shell `lib/features/home/`
- Auth/sessioni/biometria: `lib/core/auth/` (`auth_controller.dart` gestisce anche 426 e
  keepalive); API: `lib/core/api/` (Dio + interceptor 426 in `api_providers.dart`)
- Feature: `lib/features/{login,search,email,chat,settings,server,about,splash}/`
- Modelli: `lib/shared/models/` · Tema: `lib/core/theme/app_theme.dart`
- Test: `test/` (widget + unit; girano in CI su ogni push)

## Documentazione di riferimento (nel repo server PRIVATO, path locali)

- **Brief completo dell'app** (funzionalità, decisioni, storico release §15):
  `D:\sviluppo\cercaposta\docs\mobile-apps.md` — i path `mobile/…` citati lì si leggono
  come path dalla radice di QUESTO repo.
- Superficie backend per le app: `D:\sviluppo\cercaposta\docs\mobile.md`
- Sistema aggiornamenti/compatibilità: `D:\sviluppo\cercaposta\docs\aggiornamenti.md`
- Registro floor: `D:\sviluppo\cercaposta\backend\app\core\compat.py`

Le modifiche che toccano il contratto client/server (nuovi endpoint, campi `/meta`, floor)
si progettano INSIEME al repo server e si documentano lì; qui si documenta solo il client
(questo file e i commenti nel codice).
