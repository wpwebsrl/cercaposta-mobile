# Android lint policy and informational diagnostics — 18 October 2026

**Subsequent follow-up:** [official SDK registration and logging levels](android-build-logging.md) fixes the legacy SDK cause and verifies ordinary output without residual INFO at native LIFECYCLE, with warning/error visibility. All 569 unsigned AAB entries and the debug APK are unchanged. The new follow-up has 47 tool tests and fresh lint 0/0; counts below remain the preceding lint audit. Verbose/info diagnostics are still available. No release occurred.

This local follow-up addresses the seven advisories recorded by the
[native compatibility audit](android-native-compat.md), preserving artwork,
minSdk/compileSdk/targetSdk 23/36/36, Flutter 3.32.3/Dart 3.8.1 and JDK 17.
AGP 8.13.2, KGP/stdlib 2.3.21, bundled R8 8.13.19, NDK 27.0.12077973,
Build Tools 35.0.0 and desugaring 2.1.5 remain the qualified versions.
No release, remote workflow or device installation is recorded here.

## Wrapper and narrow exceptions

Gradle 8.13 is upgraded to **8.14.6**, addressing the available-update notice.
The [AGP matrix](https://developer.android.com/build/releases/agp-8-13-0-release-notes)
requires Gradle 8.13 or later and JDK 17; the
[Kotlin matrix](https://kotlinlang.org/docs/gradle-configure-project.html) covers
Gradle 8.14.6 with KGP 2.3.21. Refer to the
[release notes](https://docs.gradle.org/8.14.6/release-notes.html) and
[official checksums](https://gradle.org/release-checksums/).

```text
gradle-8.14.6-all.zip SHA-256:
24fc39aedd1b68c3de8e4d46a0277c9b42d9ccdb172231a634fad54a3693e50a
gradle-wrapper.jar SHA-256:
ad16bca46cb71bb5887c546860d93992aeee35c1fdaf4a242b0a612375d937e0
```

`android/app/lint.xml` explicitly records six intentional cases:

- One `UnusedAttribute` message for `localeConfig`, API 33, current minimum 23.
  Older systems ignore it and retain the Flutter language picker. The declaration
  is required for the system picker on Android 13+. The exact message regex does
  not match unrelated attributes or another minimum API.
- Five `IconLauncherShape` findings, limited to the five existing legacy
  `src/main/res/mipmap-{density}/ic_launcher.png` paths listed individually.
  Their approved white background remains unchanged on API 23–25; API 26+
  already selects the adaptive icon. No wildcard admits future icons, and other
  icon checks remain enabled.

These six cases are deliberate exceptions, not six changed graphics. There is
no lint baseline, blanket issue disable, reduced check list or minimum-SDK increase.
`warningsAsErrors=true` stops builds on new warnings. Reevaluate the policy when
changing artwork, language configuration or the minimum API. The resource-policy
tests protect the scope and required runtime declarations. The compatibility
loader test now reads the Gradle version from the wrapper instead of assuming an
older installed distribution.

## Informational output

`tool/flutter_jdk17.py` sets `FLUTTER_SUPPRESS_ANALYTICS=true` only in its child
environment. Flutter 3.32.3 uses `NoOpAnalytics` for this value, including nested
Gradle-launched Flutter processes. This removes repeated first-run consent
banners without editing global preferences or filtering output.

The following diagnostics remain visible in detailed logs:

| Diagnostic | Analysis and policy |
|---|---|
| Missing `fontFamily`, codepoint 128842/U+1F74A | A `printTrace` from Flutter's icon subsetter. MaterialApp and CupertinoApp deliberately use that Unicode Inspector glyph with the system font. Material/Cupertino asset fonts are processed normally; `uses-material-design:true` is present. Do not change the theme/framework or disable tree shaking to remove it. |
| R8 unmatched Proguard rules | Generated AAPT rules, AGP defaults and dependency consumer rules have no matching classes/members in this variant. Keep them for other variants and future provider versions. These are `INFO`, not compiler warnings. |
| R8 inconsistent InnerClasses/EnclosingMethod metadata | Originates in `play-services-fido:21.0.0`, `com.google.android.gms.internal.fido.zzel$zza`. JDK 17 javap confirms InnerClasses and no EnclosingMethod. R8 explicitly ignores inconsistent metadata entries. Do not patch vendor bytecode or strip keep rules to silence it; retain real-device passkey qualification. |
| SDK `Parsing legacy package` | Normal trace while discovering extracted command-line tools via source.properties. Distinct from the resolved SDK XML schema warning. Do not manufacture package metadata or rewrite global SDK namespaces. |
| Cache/compile avoidance/task/daemon/font reduction reports | Expected verbose build activity. A `NO-SOURCE` app native unit task is not counted as executed unit tests. |

No output filters, `-dontwarn` or `-ignorewarnings` were introduced. Native
deprecation, D8/R8 compatibility and SDK XML diagnostic gates remain enabled.
The gate now also rejects actual missing-font-family assets (`Expected to find
fonts for ...`). A regression test distinguishes that problem from the Inspector
trace and ordinary R8/SDK information; it does not rewrite build output.

## Qualification

Debug qualification succeeds with JDK 17.0.20.1 and Gradle 8.14.6: 12m38s,
770 tasks executed. A new offline Gradle process performs the runtime report,
assembleDebug, testDebugUnitTest and lintDebug in 6m36s: 1026 tasks,
294 executed/732 up-to-date. The app native unit task is `NO-SOURCE`.

Lint reports **0 errors/0 warnings** with the reviewed policy. A real negative
probe temporarily empties that policy, keeping warnings-as-errors enabled:
exactly six findings become errors and stop the build (exit 1, 1m47s).
Restoring the exact original bytes returns lint to zero (exit 0, 1m31s).
An initial probe with an alternate lintConfig was insufficient because lint
also discovers the original lint.xml; that attempt was not accepted as proof.
The corrected probe uses a backup and restoration in finally.

Flutter analysis is clean (85.8s), and all **227 tests pass** (1m57s).
There are **41 passing tool tests**: diagnostic gate 8, workflow 6, real loader 6,
SDK 7, JDK 2, resources 3, signature 8 and one Java fixture with six simulated
API cases. Device/ART/OEM qualification is separate.

The debug APK and its preceding nativefix build have the same 660 entries.
All 533 Android resource entries, 16 other asset entries, eight native libraries,
the manifest and every DEX are byte-identical. Only the kernel and three signing
entries change; no Dart UI source was edited. Build ID lengths differ, so simple
string replacement is not a valid proof of whole-kernel byte identity.
Consent banners are absent from debug/native logs without output filtering.

The ARM64 QA bundle succeeds in **7m19s**, 892 tasks (841 executed/51 up-to-date),
with actual R8 execution, Dart obfuscation/separate symbols, vital lint and the
full Flutter postcheck. Its synthetic signature is verified and the disposable
key removed. No real upload key is used. This is not a Store deliverable or an
all-ABI release qualification. All three logs pass the diagnostic gate with
zero compiler/native-deprecation/SDK XML/missing-font findings. Consent banners
are absent in all three logs; six SDK metadata files pass schema validation.

The remaining R8 output comprises **23 INFO lines**: 21 unmatched rules and two
lines for the same FIDO metadata case. Its transformed input JAR is byte-identical
to the preceding build. One Inspector font trace remains. Keep these diagnostics
visible; do not alter vendor inputs or font rendering to silence them.

Current debug APK:

```text
build/local/CercaPosta-Android-multilingua-local-jdk17-lintfix-20261018.apk
Build ID: local-multilingua-20261018-lintfix
Bytes: 189763328
SHA-256: ec8ce241345d018236fdd53cfc0bd025cd5d06b32f880b270e8a9a2cb882c606
```

Android Debug signature, compiled IT/EN/ES, three Flutter ABIs, native locales,
splash/notification resources and 18 backup exclusions are verified. Gradle,
Flutter and dated APK copies match. All 53 original patched-input source hashes,
pubspec/lock and ten source PNG hashes remain unchanged. App version/code remain
1.6.0/1; SDK support and runtime source are unchanged. No device installation,
remote workflow, commit, push or release was performed in this follow-up.

Local checks cannot certify device/OEM behavior. Check cold start and launchers
on API 23–25/26–32/33+, system and Flutter language selection, IT/EN/ES layouts,
font scaling/accessibility, notification/background work, voice, biometric/passkey
and backup/transfer policies. Release signing and store delivery remain separate.
