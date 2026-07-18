import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma release: legge android/key.properties (NON committato, in .gitignore).
// Se il file manca (dev/CI senza keystore) si ripiega sulla debug key.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "it.cercaposta.app"
    // Fissati a 36 invece dei default di Flutter 3.32 (che sono 35): dal 31 agosto 2026
    // Google Play rifiuta nuove app E aggiornamenti che non targettino Android 16 (API 36).
    // Togliere l'override quando si passerà a Flutter 3.35+, che porta già 36 di suo.
    compileSdk = 36
    // Pinned esplicitamente: alcuni plugin (es. flutter_secure_storage, path_provider)
    // richiedono questa versione NDK, più recente del default di Flutter.
    ndkVersion = "27.0.12077973"

    compileOptions {
        // flutter_local_notifications 18.x (notifiche di sistema, docs/notifiche.md) usa API
        // java.time e richiede il core library desugaring sui minSdk < 26.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "it.cercaposta.app"
        // minSdk 23: requisito di local_auth (BiometricPrompt) e necessario
        // per il backend AES di flutter_secure_storage (EncryptedSharedPreferences).
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Usa la chiave di upload se key.properties è presente, altrimenti debug
            // (così `flutter run --release` funziona anche senza keystore).
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required by flutter_local_notifications for core library desugaring (see compileOptions).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
