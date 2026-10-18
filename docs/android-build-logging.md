# Android build logging and official SDK registration

The shared [Android build runner](../tool/build_android.py) now automates the
procedure below for local development and both Android CI jobs. Source changes
to CI remain local until an explicitly authorized push; no remote run is implied.

## Build commands shared with CI

Run from this repository's root, with Python 3.10+, the qualified Flutter 3.32.3
SDK, a full JDK 17 and an SDK profile prepared by `tool/prepare_android_sdk17.py`.
First resolve dependencies with `flutter pub get --enforce-lockfile`. Use a new
log directory each time; existing evidence is deliberately never overwritten.
Only one build may run in a given checkout at a time.

```bash
python3 tool/prepare_android_sdk17.py --source-sdk "$ANDROID_HOME" \
  --destination "$BUILD_SDK" --java-home "$JAVA_HOME"
python3 tool/build_android.py --variant debug --lint \
  --java-home "$JAVA_HOME" --flutter-sdk "$FLUTTER_ROOT" --android-sdk "$BUILD_SDK" \
  --app-build local-check --app-build-date 2026-10-18 \
  --log-dir build/check-logs/debug-001
```

On PowerShell use `python -X utf8`, `$env:JAVA_HOME` / `$env:FLUTTER_ROOT`, a
task-specific `$buildSdk` variable, and PowerShell continuation syntax or one line.
No machine-specific path or signing value belongs in tracked files.

The runner performs these sequential operations:

1. Validate JDK 17, Flutter/Dart version, SDK metadata and the verified profile
   marker; validate the requested variant, ABIs, build identity and options.
2. Run official `flutter build apk --config-only` in the selected mode. It writes
   local build/version settings and the correct debug/release plugin registrant;
   it does not compile an APK. It also prepares release AAB builds. Keep plugin
   regeneration enabled: `--no-pub` would skip it in this Flutter version.
3. Normalize only the two SDK paths in generated `android/local.properties`
   through the existing JDK helper, without changing version/build settings.
4. Run the project wrapper with `:app:assembleDebug` and optionally `:app:lintDebug`,
   or `:app:bundleRelease`. Set `-Dorg.gradle.logging.level=lifecycle`,
   `--console=plain --warning-mode=all`. Gradle has no `--lifecycle` CLI flag.
5. Run the ordinary, complete Flutter APK/AAB command, including Flutter's native
   postchecks. Native compilation has already run with warnings visible.
6. For release, verify the final bundle's signing certificate through the existing
   verifier under the same JDK 17 environment. Record the artifact size and SHA-256.

`configuration.log`, `sdk-paths.log`, `native.log`, `flutter.log` and, for release,
`signature.log` contain complete merged stdout/stderr. Output is teed as bytes to
the console and files without line filters. `result.json` records passed/failed
state; exit code, completion markers and the existing compiler-diagnostic gate
are checked at every stage. A failed stage prevents every later stage. Other
warnings remain visible even when they do not match a rejecting gate rule.

Common inputs are constructed once: main entry point, explicit three supported
ABIs by default, APP_BUILD/date, optional build-name/number and additional
`--dart-define` values. Native defines include Flutter's six automatic version
defines in exactly the same order. Flutter's effective debug icon-shaking flag
is false; release uses true. The adapter refuses unqualified Flutter/Dart upgrades
and unsupported options instead of guessing their native mapping. Review it when
adding build flavors, deferred components or a new toolchain.

Release usage preserves the existing CI signing gate, versionCode allocation,
Dart obfuscation and debug symbols:

```bash
python3 tool/build_android.py --variant release \
  --java-home "$JAVA_HOME" --flutter-sdk "$FLUTTER_ROOT" --android-sdk "$BUILD_SDK" \
  --app-build local-qa --app-build-date 2026-10-18 --build-number 123 \
  --split-debug-info build/symbols --log-dir build/check-logs/release-001
```

`ANDROID_UPLOAD_CERT_SHA256` and an approved non-debug signing configuration are
mandatory; never put passwords in command arguments or logs. Local QA uses
disposable synthetic keys through the existing signing-properties override and
does not exercise a real upload key. The script neither installs nor uploads.

For native investigation add `--native-info`: warning-mode remains all, while
the complete native INFO stream is retained. For full Flutter tool/font diagnosis
also run the corresponding Flutter command with `--verbose` through
`tool/flutter_jdk17.py` and save a separate complete log. This diagnostic command
does not replace the mandatory native LIFECYCLE check.

Both Android CI jobs invoke this runner, without a shell pipe masking its exit
code. Debug includes native lint. Release retains its quality/backend prerequisites,
signing verification, build-number offset, symbol and bundle artifact rules.
Diagnostic logs are retained even when a build fails; only their upload step uses
`always()`. Bundle promotion still requires success. All Actions remain pinned.
CI edits and local Windows validation are not proof of an executed Ubuntu workflow.

## Local qualification of the shared runner

All **60 tool tests pass**, including ten builder cases, eight workflow cases
and a real Gradle integration test with three cases. The real test verifies that
LIFECYCLE keeps warning/error messages despite a project quiet setting, INFO mode
restores information, and the expected build failure is rejected. These synthetic
messages belong to a test fixture, not app build defects.

YAML parsing, immutable Action pins and Bash syntax for all **31 Android run
blocks** pass locally; those blocks were not executed as a remote workflow.
The adapter was compared with actual canonical Flutter commands retained from
the preceding qualification: seven debug and eight release properties agree,
including the six automatic defines, with host path normalization applied.

The final debug runner succeeds: native assemble plus lint in **2m12s**, 1,023
tasks (16 executed/1,007 up-to-date), then Flutter's complete APK postcheck
(Gradle phase **82.7s**). Lint reports **0 errors/0 warnings**, with the same six
intentional exceptions. The resulting APK is **byte-identical** to the existing
lintfix APK; all three local copies retain its size and SHA-256. No UI, catalog,
Dart source, artwork or supported Android API was changed by this automation.
The preceding 227 Flutter tests/analyze remain historical evidence, not newly
executed counts for this change to build tools.

The release runner also passes with a disposable synthetic signing key: native
ARM64 bundle build **1m12s**, 892 tasks (15 executed/877 up-to-date), then the full
Flutter AAB postcheck (Gradle phase **151.5s**) and certificate verification.
The debug-to-release plugin registrant transition is verified. All **569
non-signature entries are byte-identical** to the preceding QA bundle. Only root
META-INF signature files are excluded, not arbitrary META-INF payloads. The key
is removed afterward; no real upload key is used. R8 is up-to-date in this run;
its forced execution remains evidence from the previous qualification below.
Ordinary font-size optimization status messages remain visible. This ARM64 QA
bundle does not qualify an all-ABI release or constitute a Store artifact.

The first local run caught an invalid `--lifecycle` option and stopped before
Flutter's postcheck. It was corrected to the supported logging system property;
the new real Gradle test covers this behavior. Comparing actual Flutter commands
also caught Windows entry-point slash normalization before final qualification.
The failed initial log was preserved.

The SDK/logging measurements below precede automation of the shared runner.

Local follow-up, 18 October 2026, to the [lint qualification](android-lint.md).
JDK 17, Gradle 8.14.6, AGP 8.13.2, KGP/stdlib 2.3.21, R8 8.13.19,
Flutter 3.32.3/Dart 3.8.1 and app SDK 23/36/36 remain unchanged.
No release, remote workflow or device installation is performed here.

## What can disappear safely

| Diagnostic | Treatment |
|---|---|
| SDK `Parsing legacy package` | Fix the cause by registering the same command-line tools with authentic Google-installer metadata. It disappears even in verbose SDK inspection. |
| Flutter Inspector U+1F74A/fontFamily trace | Use ordinary Flutter output. The unmodified icon subsetter emits this only with printTrace; keep verbose mode available for diagnosis. No font/framework/theme change. |
| R8 unmatched-rule/FIDO INFO | Use Gradle's normal LIFECYCLE level with warning-mode all. AGP sends these to logger.info, while warnings/errors use their corresponding levels. Keep INFO mode for diagnosis; do not edit vendor rules or classes. |

The SDK cause is corrected; the other information remains available at the
diagnostic level. No output-line filters, custom diagnostics handlers, Proguard
suppression, compiler fork or application changes are introduced.

Flutter 3.32.3 uses Gradle `--info -Pverbose=true` for its verbose build and `-q`
otherwise. **A quiet Flutter build alone does not prove native warning visibility.**
Qualify native builds separately at LIFECYCLE with `--warning-mode=all`, then run
the ordinary Flutter command for its full postcheck. Avoid quiet mode as the only
native quality check. See [Gradle logging](https://docs.gradle.org/current/userguide/logging.html).

## Reproducible registration

`tool/prepare_android_sdk17.py` now detects missing command-line tool registration.
It obtains package.xml from a real Google SDK-manager installation in a temporary
SDK, reusing accepted licence records and closed stdin. All packages' identity,
revision, compatible schemas and complete file hashes are checked before any
metadata is copied to the build SDK. Binaries/platforms and the global SDK remain
untouched. Existing registrations are reused without another download.

The local profile registers tools 19.0 and 23.0; fresh profiles that only contain
tools 19.0 do not acquire tools 23.0 implicitly. The first registration needs a
temporary official download. Unexpected versions, schemas, identities or changed
bytes stop preparation; do not bypass the guard by rewriting namespaces or hashes.

The local official installations match all 247 tool files (108 + 139).
Before/after checks cover 263 tool and selected build-input files; all match.
Eight SDK metadata files validate. Official verbose installed-package inspection
lists both versions with zero legacy-package or SDK XML compatibility messages.

The SDK tests include six new regressions, 13 cases total: registration reuse,
source preservation, directory/version checks, byte mismatch, metadata identity/
revision/schema rejection and validation of all packages before copying metadata.

## Alternatives investigated

The two Flutter tool sources match the official 3.32.3 tag after LF normalization:
[Gradle invocation](https://github.com/flutter/flutter/blob/3.32.3/packages/flutter_tools/lib/src/android/gradle.dart)
and [icon subsetter](https://github.com/flutter/flutter/blob/3.32.3/packages/flutter_tools/lib/src/build_system/targets/icon_tree_shaker.dart).
They are not patched.

An isolated fixture using the real R8 confirms that `-dontnote **` does not remove
the unmatched-rule INFO. The CLI mapping for UnusedProguardKeepRuleDiagnostic can
hide it with identical fixture bytecode; this is suppression, not a fix to vendor
rules or a drop-in AGP Proguard setting, and is not used in the project. The FIDO
messages are generic StringDiagnostic instances, so a type-wide suppression would
also hide other information. Normal logging levels avoid that custom machinery.

An independent Gradle fixture verifies that LIFECYCLE retains warnings/errors,
INFO mode shows the information again, and an expected failure returns nonzero.

## Project verification

The standard native ARM64 QA build succeeds in **3m59s**, 893 tasks (43 executed/
850 up-to-date), with R8 forced to execute, LIFECYCLE and warning-mode all. The
ordinary Flutter appbundle command then succeeds with its complete postcheck
(Gradle phase 136.9s). Both logs pass the existing gate with none of the residual
messages. Synthetic signing is verified and the temporary key removed; no real
upload key is used.

All **569 unsigned bundle entries are byte-identical** to the preceding QA
bundle, including code, manifest, libraries, fonts/resources, metadata and mapping.
Only the three root META-INF signature files differ. This is stronger evidence
than a shorter console output: compiled application contents are unchanged.
The private QA bundle is not a Store deliverable or all-ABI release qualification.

All **47 tool tests pass**: SDK 13, diagnostic gate 8, workflow 6, loader 6, JDK 2,
resources 3, signature 8 and one Java fixture with six simulated API cases.
The three Gradle logging cases and three isolated R8 options cases pass separately.
Full native lint with the registered SDK succeeds in **1m56s**: 969 tasks,
13 executed/956 up-to-date, **0 errors/0 warnings**, the same six intentional
exceptions as the preceding audit. No warning-mode reduction.

No Dart/UI source or catalog was changed. The preceding 227 Flutter tests and clean
analysis remain historical evidence, not rerun counts for this SDK/log-only follow-up.
Keep complete info/verbose logs for toolchain/plugin/font/new-language qualification
and incident diagnosis. Ordinary verbosity and warning visibility do not replace
those logs, compiled-artifact comparison or visual checks on devices.

The current debug APK and device checklist remain in [localization status](localization.md).
Its bytes, build ID, three Flutter ABIs and IT/EN/ES are unchanged; no new debug
APK/version is needed for metadata registration and a logging procedure.
Device/OEM behavior, real upload signing and all-ABI release qualification remain
separate. Diagnostic logging policy is not proof of runtime correctness.
