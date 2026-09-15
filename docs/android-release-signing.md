# Firma verificata delle release Android

Le build `debug` mantengono la propria chiave di sviluppo. Le build `release` richiedono la chiave di upload autorizzata: non esiste un fallback alla chiave debug.

`android/key.properties` rimane escluso da Git e contiene `storeFile`, `storePassword`, `keyAlias`, `keyPassword`. `storeFile` è risolto rispetto ad `android/app`, come in precedenza. Occorre inoltre l'impronta SHA-256 del **certificato di upload**, che può differire dal certificato usato da Google Play per firmare gli APK distribuiti. Impostarla come `ANDROID_UPLOAD_CERT_SHA256`, proprietà Gradle `cercaposta.uploadCertSha256`, oppure `certificateSha256` nel file locale, in quest'ordine di precedenza. Sono ammessi digest esadecimali con o senza due punti.

Il task `verifyReleaseSigning`, richiesto da `preReleaseBuild` e `validateSigningRelease`, verifica presenza dei dati, chiave privata dell'alias, validità del certificato e impronta attesa; rifiuta alias/certificati debug. Un errore interrompe la release. La sola presenza del file non basta più.

Nel workflow mobile configurare la variabile pubblica `ANDROID_UPLOAD_CERT_SHA256` e i secret già usati `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_PROPERTIES`. Dopo la firma, `tool/verify_android_artifact.py` verifica il bundle prima del caricamento dell'artefatto. Non impostare una nuova impronta soltanto per far passare una build: deve corrispondere alla chiave di upload approvata in Play Console, oppure alla procedura di rotazione già autorizzata.

Verifica manuale, con JDK 17 e Android SDK disponibili:

```sh
python3 tool/verify_android_artifact.py build/app/outputs/bundle/release/app-release.aab
python3 tool/verify_android_artifact.py percorso/app-release.apk --sha256 IMPRONTA_APPROVATA
```

Per AAB, il verificatore Java legge ogni elemento e verifica la firma JAR, esige un unico firmatario approvato per tutti i payload, incluso `META-INF/services`, e rifiuta percorsi ambigui o duplicati. Per APK usa `apksigner` dell'Android SDK, poi controlla impronta e assenza di certificato debug. Nessun verificatore legge password della keystore o modifica l'artefatto.

Regressioni automatiche: `python3 -m unittest discover -s tool -p test_android_bundle_signing.py -v` genera chiavi sintetiche temporanee e prova bundle validi, non firmati, alterati, con firmatario inatteso, con chiave debug e con file aggiunti/percorsi ambigui. `python3 tool/check_android_signing_gate.py` verifica il vero task Gradle con configurazioni assenti/errate e chiave sintetica valida. L'override `-Pcercaposta.signingProperties=...` serve a queste prove isolate e non modifica i secret locali.

Le verifiche locali non firmano né pubblicano una release con le chiavi dell'operatore. La continuità degli aggiornamenti va collaudata su una versione precedente distribuita dallo stesso canale, usando il certificato e il versionCode previsti; per Play App Signing, usare un track di test della Console. Non tentare di sostituire un'app installata dallo store con l'APK sintetico dei test.
