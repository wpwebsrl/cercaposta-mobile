pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    // Stage reviewed native patches outside the shared Pub/Flutter installations.
    settings.extra["cercapostaOriginalFlutterSdk"] = flutterSdkPath
    apply(from = file("../tool/android_compat.gradle"))
    includeBuild(settings.extra["cercapostaFlutterGradle"] as String)

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Qualified together: SDK 36, bundled R8 Kotlin 2.3 support, Gradle 8.13, JDK 17.
    // The installed plus_plugins require AGP >= 8.12.1 and Gradle >= 8.13.
    // See docs/android-toolchain.md before changing any member of this set.
    id("com.android.application") version "8.13.2" apply false
    id("org.jetbrains.kotlin.android") version "2.3.21" apply false
}

include(":app")
