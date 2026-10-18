# Android toolchain qualification — 18 October 2026

Current local/CI build commands use the [shared JDK 17 build runner](android-build-logging.md),
with native diagnostics visible, lint and a full Flutter postcheck. The reproduction
commands and measurements below describe the earlier toolchain qualification.

**Latest follow-up:** [lint/INFO qualification](android-lint.md) records Gradle 8.14.6/JDK 17, zero current lint findings with six narrow intentional exceptions and the lintfix APK. The compiler/toolchain measurements below remain historical. No release was performed.

**Subsequent qualification:** the [native compatibility and SDK follow-up](android-native-compat.md)
keeps this compiler set and resolves the third-party deprecations and SDK XML
warning left open here. It records the new nativefix APK and maintained source
patches/build SDK profile. Counts and artifacts below describe the earlier compiler
qualification; current results are in the follow-up and localization status.

This document records a local development upgrade. It does not record a Store
submission or deployment. See [localization status](localization.md) for the current
test APK and [native quality](android-quality.md) for the separate resource advisories.

## Why the old versions needed to change

The app used AGP 8.9.1, bundled R8 8.9.32, Gradle 8.12 and Kotlin Gradle plugin
2.1.0. Its resolved Kotlin standard library was already 2.2.0 through the installed
`share_plus` 12.0.2 and `package_info_plus` 9.0.1. Both installed packages explicitly
require Java 17, AGP >=8.12.1 and Gradle >=8.13. The old compiler emitted 1851
Kotlin-metadata diagnostics involving 926 distinct classes. AGP 8.9 also documented
a maximum compile API of 35 while this app already used 36.

The upgrade respects the installed plugin requirements, the Android compiler matrix
and the Kotlin Gradle-plugin matrix together. Merely forcing an older stdlib or
overriding the R8 dependency would leave other parts of the build mismatched.

| Component | Previous local baseline | Selected baseline |
|---|---|---|
| JDK | Temurin 17.0.20.1+1 | Same; CI Adoptium semver 17.0.20+101 |
| Gradle wrapper | 8.12 all | 8.13 all, official distribution SHA-256 pinned |
| Android Gradle plugin | 8.9.1 | 8.13.2 |
| Bundled D8/R8 | 8.9.32 | 8.13.19, supplied by AGP |
| App Kotlin Gradle plugin | 2.1.0 | 2.3.21 |
| Flutter / Dart | 3.32.3 / 3.8.1 | Unchanged |
| min / compile / target SDK | 23 / 36 / 36 | Unchanged |
| NDK / SDK build tools | 27.0.12077973 / 35.0.0 | Unchanged |
| Core-library desugaring | 2.1.5 | Unchanged |
| Local SDK command-line tools | Missing | 19.0; sdkmanager and apkanalyzer run with JDK 17 |

[AGP 8.13.2](https://developer.android.com/build/releases/agp-8-13-0-release-notes)
bundles R8 8.13.19 with Kotlin 2.3 support, uses Gradle 8.13 and JDK 17, and supports
API levels through 36.1. The [Kotlin compatibility matrix](https://kotlinlang.org/docs/gradle-configure-project.html)
covers Gradle 8.13 and AGP 8.13.2 with KGP 2.3.21. The older KGP 2.2.x matrix stops
below the AGP requirement of the installed plugins. This is why updating just the
app compiler to 2.2 was not the selected qualification path. Android's
[compiler requirements](https://developer.android.com/build/kotlin-support)
also cover class files from transitive Kotlin dependencies.

The app's Java/Kotlin bytecode target remains 11; it is independent of the JDK used
to run Gradle and of the Android API level. The app now uses Kotlin's typed
`compilerOptions` DSL instead of its deprecated `kotlinOptions` block. Package
versions in `pubspec.yaml` and `pubspec.lock` are not changed for this upgrade.

AGP 8.13 also validates AAR dependency metadata for library modules. This exposed
`biometric_storage` 5.0.1 compiling against API 31 while its AndroidX dependencies
require API 33/34. The root Gradle project now uses `finalizeDsl` to align only this
library's compileSdk with the app's API 36. Its minSdk, targetSdk, source package and
runtime biometric/secure-storage behavior are not changed; no Pub-cache patch or
metadata-check bypass is used.

Windows builds whose Pub plugin sources and build outputs are on different drives
also exposed Kotlin incremental-cache relocation failures. Per-task overrides were
overwritten by Kotlin's configuration, so the project uses the supported properties
`kotlin.incremental=false` and `kotlin.compiler.execution.strategy=in-process`.
These apply on all hosts: a Kotlin task that runs compiles its complete sources,
while Gradle up-to-date checks and build caching still work. This trades Kotlin's
partial compilation for reproducibility and does not change runtime behavior.
JVM encoding is explicitly UTF-8; machine-wide Java settings remain unchanged.

The signing verification helpers now explicitly use UTF-8 in the JDK process and
Python decoder. This fixes localized JDK output on Windows under Python UTF-8
mode: the earlier run could report passing tests while a subprocess reader thread
raised `UnicodeDecodeError`. The corrected eight-test run is checked for these
thread failures as well as its exit status.

The newer lint also detects malformed escaping of Windows SDK paths in the local,
ignored `android/local.properties`. Flutter 3.32's Windows generator can recreate
unescaped drive separators. After running a Flutter build on Windows and before
native lint, normalize just these two path fields using JDK 17 from the repo root:

```text
java -Dfile.encoding=UTF-8 tool/NormalizeAndroidSdkPaths.java android/local.properties
```

The utility preserves other lines, uses Java's property escaping, supports Unicode
paths and is idempotent. It changes only the local development file; it neither
patches Flutter nor stores workstation paths in version control. Synthetic Windows
path/Unicode/CRLF/preservation checks and a repeated no-change run were performed.

## Reproduction and regression checks

Set `JAVA_HOME` to a full JDK 17 installation and put its `bin` first in `PATH` for
the build process. Do not change the machine's global Java configuration. From
`android`, use the project wrapper (`gradlew.bat` on Windows):

```text
./gradlew --version
./gradlew :app:assembleDebug :app:testDebugUnitTest :app:lintDebug --console=plain
./gradlew :app:dependencies --configuration coreLibraryDesugaring --console=plain
./gradlew :app:dependencyInsight --dependency org.jetbrains.kotlin:kotlin-stdlib --configuration debugRuntimeClasspath --console=plain
```

For a compiler qualification, use a cold build or `--rerun-tasks --no-build-cache`;
an incremental run that skips D8 is not evidence that its old warning is gone.
Capture the complete log and check it using
`python tool/check_android_build_log.py BUILD_LOG`. The checker rejects D8/R8
warnings and Kotlin compatibility failures even when Gradle reports success.
It also rejects incomplete/failed logs; unrelated plugin deprecations and the
documented native resource advisories remain visible.

The local workflow changes capture the Flutter debug build, native lint and release
bundle with `tee` plus `pipefail`, then run this checker. Six diagnostic regression tests,
five workflow-gate tests and two native-resource-policy tests cover the checks.
Workflow changes are local source changes; no remote run is implied.

Wrapper distribution SHA-256:
`fba8464465835e74f7270bbf43d6d8a8d7709ab0a43ce1aa3323f73e9aa0c612`.
Official wrapper JAR SHA-256:
`81a82aaea5abcc8ff68b3dfcb58b3c3c429378efd98e7433460610fecd7ae45f`.
The wrapper scripts/JAR must be generated by the selected Gradle release and
checked against the [official Gradle checksums](https://gradle.org/release-checksums/).
The old ignore rules for wrapper launchers/JAR were removed so these verified
files can be versioned with their properties. Attributes preserve LF for the Unix
launcher, CRLF for the Windows launcher and binary handling for the JAR. Linux
Android jobs explicitly make the launcher executable after checkout. No commit
or push is implied. Regenerate a Windows wrapper in a separate invocation before
building: replacing a running `.bat` can cause misleading trailing shell errors.

Keep release signing checks enabled. A local R8/release-variant test may use an
explicit disposable synthetic keystore and matching test fingerprint. It must not
use a real upload key or become a Store artifact. A debug APK remains the ordinary
local test deliverable. Neither a local build nor synthetic signing validates a
real Store release, installation upgrade or device runtime.

Use the Flutter build command when changing between debug and release; do not skip
platform tooling regeneration with `--no-pub` in that transition. A debug registrant
can contain dev-only native plugins such as the splash generator, which are absent
from the release classpath. Run `flutter pub get --enforce-lockfile` first and verify
that the subsequent build preserves the lock. Generated registrants stay generated;
the splash generator is not moved into runtime dependencies to work around this.

The local SDK lacked command-line tools: Gradle/R8 completed the bundle, but Flutter
could not perform its final native-symbol check. Installed only Google's tools 19.0
under the configured SDK, with the official repository archive SHA-1 checked:
`54a582f3bf73e04253602f2d1c80bd5868aac115`.
Archive `commandlinetools-win-13114758_latest.zip` has recorded SHA-256
`98b565cb657b012dae6794cefc0f66ae1efb4690c699b78a614b4a6a3505b003`.
Both `sdkmanager` and an actual `apkanalyzer apk summary` run succeeded on JDK 17.
The subsequent Flutter bundle command also passed its final check. Platforms,
build tools and NDK were not intentionally upgraded. The old SDK-XML v3/v4 warning
remains separately visible; it is not a Kotlin metadata diagnostic or a claim of
Store readiness.

## Local verification outcome

The 1851 old D8 Kotlin-metadata diagnostics are absent from the final debug,
native-lint and release/R8 logs. Runtime inspection confirms the selected compiler
versions, matching stdlib, UTF-8 and the project's Kotlin-cache settings. The final
offline native run succeeds in 2m12s with 1026 tasks (20 executed, 1006 up-to-date),
including one temporary diagnostic task. App native unit tests have no sources.
Lint has **0 errors and 7 advisories**: localeConfig (1), legacy launcher shape (5)
and availability of Gradle 8.14.6 (1). The qualified Gradle remains 8.13.

Flutter analysis is clean and all 227 Flutter tests pass. Diagnostic/workflow/resource
tests pass (6/5/2), as do eight signature tests and six real signing-gate scenarios.
The ARM64 release-variant QA build uses Dart obfuscation and separate symbols;
R8 actually executes and the complete Flutter command, vital lint, symbol check
and synthetic signature verification pass. The synthetic key is then removed.
It does not certify the real Store key, all-ABI bundle or a device upgrade.

The current all-language debug APK, build ID and hash are in
[localization status](localization.md). ARM64, ARM32 and x86_64 Flutter libraries,
IT/EN/ES text, the debug certificate and native resources are verified. Preserve
the exact Flutter `dart-defines`, targets and build options when running another
native assemble: otherwise the package build ID can revert to its default.

During this earlier compiler qualification, plugin/Flutter deprecations, Groovy
assignments, ignored manifest namespaces and the SDK XML warning remained visible.
The subsequent [native compatibility work](android-native-compat.md) resolves those
emitted diagnostics through reviewed build copies and an isolated SDK, preserving
the original caches and package versions. Hardware and actual CI execution remain
outstanding; no commit, push, upload or release occurred.
