# Android native compatibility and SDK metadata — 18 October 2026

**Latest SDK/logging follow-up:** [official registration and log levels](android-build-logging.md) records authentic tools metadata (same binaries), eight valid package metadata files, no SDK legacy trace even with verbose inspection, and native LIFECYCLE quality checks with warnings visible. The staged native compatibility patches below remain unchanged; earlier qualification measurements are historical.

**Subsequent local qualification:** [lint policy and informational diagnostics](android-lint.md) qualifies Gradle 8.14.6 with JDK 17, 0 errors/0 warnings and six explicit design/API exceptions. It identifies the current lintfix APK and preserves artwork/runtime sources. The nativefix measurements and Gradle 8.13 references below are historical; native patch mechanisms and SDK isolation still apply. No release occurred.

This local follow-up keeps JDK 17, Flutter 3.32.3/Dart 3.8.1, Gradle 8.13,
AGP 8.13.2, KGP/stdlib 2.3.21 and bundled R8 8.13.19. App SDK levels remain
23/36/36, NDK 27.0.12077973 and Build Tools 35.0.0. No release is recorded here.
See [toolchain qualification](android-toolchain.md) for the earlier compiler fix.

`tool/android_compat_patches.json` records exact native-source replacements and
before/after SHA-256 of UTF-8 text normalized to LF: 25 components, 53 files.
`tool/android_compat.gradle` validates all inputs before staging Android plugin
directories and the Flutter Gradle plugin under `.dart_tool/android-compat`.
Gradle uses those copies. Pub caches, the shared Flutter SDK, Dart package versions
and iOS package sources are left intact. Licences and package metadata accompany
the copies. Changes upstream or to the Flutter version fail pending review; never
update the approved hashes automatically or edit a shared cache to bypass this.
All 53 original source files were rechecked. The four Flutter Gradle sources also
match the official 3.32.3 tag, independent of the local installation.

The patches modernize Groovy assignments and remove obsolete library-manifest
`package` attributes while retaining Gradle namespaces and manifest contents.
Plugin buildscript AGP coordinates match 8.13.2. Other fixes remove unnecessary
Kotlin null operators/conversions, use BluetoothManager, type the Workmanager
Pigeon map with Kotlin Any, and use PackageInfoFlags on API 33+. The same current
APK signers and SHA-256 fingerprint format are retained. Two narrow legacy helper methods explicitly
retain deprecated APIs required on Android 23–32; local annotations document this
constraint. There is no global warning suppression or SDK support-floor change.
Flutter Gradle uses filePermissions 0644, the modern minSdk API and injected
ExecOperations instead of accessing Task.project during execution.

These are maintained compatibility patches, not upstream package releases. They
cost disk space and maintenance. When upgrading Flutter/plugins, compare upstream
changes, retire superseded patches and qualify the replacement build. Current
upstream package releases may require a newer Flutter/Dart and broader migrations.

## SDK readers and the isolated build profile

Command-line tools 23 can read the current global SDK. Use Google's modern CLI:

```text
android --no-metrics --sdk=SDK_PATH sdk list
```

The tools-23 sdkmanager launcher is a deprecated compatibility adapter. Its update
does not replace AGP 8.13's embedded reader, which only understands SDK XML v3.
An intermediate build still warned about global repository2/v4 metadata.

For AGP, `tool/prepare_android_sdk17.py` prepares a separate build SDK with the
same platform 36 revision 2 registered by official tools 19 using XML v3. It
reuses existing accepted licences, Build Tools 35 and NDK 27, and checks that the
platform/tools files match the original when those packages exist. No global XML
is rewritten, namespace string replaced, or newer platform silently accepted.
The local comparison covers 11342 platform files and 14 platform-tools files;
package.xml is deliberately excluded as generated metadata. A mismatched package
or platform revision requires review. Destinations must be separate; nonempty
unmarked directories are refused. New licences are never automatically accepted.
The profile also includes APIs 34/35 needed by existing plugins, with the same
android.jar, Java modules, source properties and build.prop as the source SDK.
Six actual package metadata files were checked. Unsupported schema declarations
are rejected even when binary hashes match; prepare a fresh profile after an IDE
rewrites its XML, rather than replacing namespace strings. A marked profile cannot
be silently switched to another source SDK.

```text
python tool/prepare_android_sdk17.py --source-sdk EXISTING_SDK --destination ISOLATED_BUILD_SDK --java-home JDK17
python tool/build_android.py --java-home JDK17 --flutter-sdk FLUTTER_SDK --android-sdk ISOLATED_BUILD_SDK --variant debug --lint --app-build local-check --app-build-date 2026-10-18 --log-dir build/check-logs/native-001
```

The Flutter wrapper uses a disposable configuration to select JDK 17 for both
the launcher and Gradle; JAVA_HOME alone loses to Android Studio's bundled JDK.
Arguments and exit codes propagate. Global Java/Flutter preferences stay intact.
On Unix a legacy home Flutter settings file takes precedence over XDG and is
explicitly refused by this wrapper; the shared build runner uses disposable settings in CI too.
Native Gradle builds continue to use JAVA_HOME/JDK 17 and the generated local
SDK property. Preserve the same Flutter build identity/dart-defines when assembling
again. Use a new Gradle process when qualifying the XML fix, not a warm reader.
The current [shared build procedure](android-build-logging.md) prepares the plugin
registrant, normalizes SDK paths, runs native compilation/lint with warnings
visible, and then runs Flutter's full postcheck. A standalone quiet Flutter build
is insufficient as a native quality gate.

Keep `.dart_tool` and local.properties ignored. The NDK link is not a separate
copy: never remove its target recursively while cleaning the isolated profile.
To roll back local SDK selection, select the previous SDK through the same wrapper;
its XML mismatch will again be reported until it is made compatible. Keep the
previous dated APK for comparison; do not install over incompatible signing keys.

## Regression checks

The real Groovy-loader fixture suite has six tests, JDK selection two, SDK-profile
guards seven, diagnostic gate seven, workflow gates six and resource policies two.
The loader integration tests need the selected Gradle wrapper distribution cached;
CI runs them after its debug build. The log gate rejects Kotlin/native deprecations,
obsolete namespace handling, Groovy/fileMode/Task.project deprecations and SDK XML
warnings even if Gradle reports success. App lint advisories remain separate.

Flutter analysis is clean and all 227 tests pass. Final build outcomes, APK identity,
hashes and device limitations are recorded in [localization status](localization.md).
No remote workflow, upload, device install or release is implied by these source changes.

The staged passkeys Java source is also compiled on JDK 17 and exercised in one
fixture with six simulated API cases: 23/27/28/32/33/36. Current/legacy signers and
the appropriate PackageManager overload are verified. This is not an ART, OEM or
hardware test. Eight signature-verifier tests pass with disposable synthetic keys.

Final debug: 8m42s, 770 tasks (769 executed, 1 up-to-date). A new offline Gradle
process runs native assemble/unit-task/lint plus one temporary diagnostic task:
4m06s, 1026 tasks (293 executed, 733 up-to-date). The app unit task has no sources.
ARM64 R8 QA: 7m06s, 892 tasks (841 executed, 51 up-to-date); actual minification,
Dart obfuscation/separate symbols, vital lint, Flutter postcheck and synthetic
signature verification pass. The key is removed. All three final logs pass the
diagnostic gate with no SDK XML warning or emitted native deprecations.

Lint remains 0 errors/7 documented advisories. The release font subsetter also
mentions U+1F74A with no fontFamily: Flutter's MaterialApp/CupertinoApp Inspector
intentionally uses that Unicode system glyph. Framework/theme/font sources were
not changed to silence it. Material/Cupertino fonts are processed normally.

Both debug APKs contain the same 660 ZIP entries; only classes2.dex, the kernel
build identity and three signing entries differ. All eight native libraries and
the compiled manifest are identical. Replacing the old build ID in the previous
kernel makes it byte-identical to the new kernel. The smaller APK size comes from
removing an unused 26504144-byte region of the previous ZIP, with no removed asset.
