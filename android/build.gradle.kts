allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// biometric_storage 5.0.1 pins compileSdk 31, below its AndroidX dependencies.
// AGP 8.13 validates AAR metadata for libraries too. Align this module with the
// app's compile SDK without changing its minSdk, targetSdk or packaged behavior.
subprojects {
    if (name == "biometric_storage") {
        pluginManager.withPlugin("com.android.library") {
            extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension> {
                finalizeDsl { library -> library.compileSdk = 36 }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
