import java.util.Properties
import java.security.KeyStore
import java.security.MessageDigest
import java.security.cert.X509Certificate

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is mandatory; debug builds keep their separate debug identity.
// An explicit file override supports isolated signing checks without changing local secrets.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file(
    providers.gradleProperty("cercaposta.signingProperties").getOrElse("key.properties")
)
if (keystorePropertiesFile.isFile) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
val expectedUploadCertificate = providers.environmentVariable("ANDROID_UPLOAD_CERT_SHA256")
    .orElse(providers.gradleProperty("cercaposta.uploadCertSha256"))
    .getOrElse(keystoreProperties.getProperty("certificateSha256", ""))
    .trim().replace(":", "").lowercase()

val verifyReleaseSigning by tasks.registering {
    group = "verification"
    description = "Require the approved non-debug upload key before a release build."
    doLast {
        check(keystorePropertiesFile.isFile) { "Release signing requires key.properties; use a debug build for local testing." }
        fun required(name: String): String = keystoreProperties.getProperty(name)
            ?.takeIf { it.isNotBlank() } ?: error("Missing release signing property: $name")
        check(expectedUploadCertificate.matches(Regex("[a-f0-9]{64}"))) {
            "Release signing requires ANDROID_UPLOAD_CERT_SHA256 or certificateSha256."
        }
        val alias = required("keyAlias")
        check(!alias.equals("androiddebugkey", ignoreCase = true)) { "Debug keys cannot sign a release." }
        val archive = file(required("storeFile"))
        check(archive.isFile) { "Release keystore does not exist." }
        val storePassword = required("storePassword").toCharArray()
        val keyPassword = required("keyPassword").toCharArray()
        try {
            val store = KeyStore.getInstance(archive, storePassword)
            val key = store.getEntry(alias, KeyStore.PasswordProtection(keyPassword))
            check(key is KeyStore.PrivateKeyEntry) { "Release alias must identify a private signing key." }
            val certificate = key.certificate as X509Certificate
            certificate.checkValidity()
            check(!certificate.subjectX500Principal.name.lowercase().contains("cn=android debug")) {
                "Debug certificates cannot sign a release."
            }
            val fingerprint = MessageDigest.getInstance("SHA-256").digest(certificate.encoded)
                .joinToString("") { "%02x".format(it) }
            check(fingerprint == expectedUploadCertificate) { "Release certificate does not match the approved SHA-256 fingerprint." }
            logger.lifecycle("Approved Android upload certificate SHA-256: $fingerprint")
        } finally {
            storePassword.fill('\u0000')
            keyPassword.fill('\u0000')
        }
    }
}

tasks.configureEach {
    if (name != "verifyReleaseSigning" &&
        (name.endsWith("Release") || name == "preReleaseBuild")) {
        dependsOn(verifyReleaseSigning)
    }
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
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.takeIf { it.isNotBlank() }?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required by flutter_local_notifications for core library desugaring (see compileOptions).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
