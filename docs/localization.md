# Localization contract and local implementation status

Local Android rebuild, **22 October 2026**. The debug APK now includes all five
languages and the German/French/Spanish linguistic corrections described below.
Build ID **`local-multilingua-reviewed-20261022`**, app version **1.6.0+1** retained.
Artifact: `build/local/CercaPosta-Android-multilingua-local-jdk17-20261022.apk`,
**216385865 bytes**, SHA-256
`c5d75527de66242656b43e8524ce79fdbace7e49b5d399f72d636a98ff487c4c`.

The shared runner used **Temurin JDK 17.0.20.1+1**, native LIFECYCLE logging with
warning-mode all, `assembleDebug`, lint (**0 errors/0 warnings**) and the complete
Flutter APK postcheck. Dependencies, lockfile, generated catalogs and toolchain
were not changed. **9 targeted tests pass**, covering the localization contract,
notification text and Spanish billing on a narrow screen with 200% text.
The actual APK passes CRC/signature checks and contains all five compiled language
declarations, localization classes and 25 current text samples checked against
the ARB sources, plus the expected SVG icons and ARM/ARM64/x64 Flutter runtimes.
The Android Debug signing certificate matches the previous local APK. Resources,
native libraries, DEX and manifest are byte-identical to that APK; only the Dart
kernel and three signature entries changed. Logs are in
`build/check-logs/multilingua-reviewed-20261022-01/`.

No agents, push, CI, release or device installation. Real-device login, language
selection/persistence, background notifications, reminder dialogs, external-browser
flows, local voice and accessibility checks remain pending. Native iOS still
requires macOS and actual devices. The 227-test full suite cited below was run
on 20 October, and was not rerun for this build. Older artifact hashes remain
historical; use the 22 October APK to test the revised translations.

Spanish linguistic follow-up, **20 October 2026**, local only. All **609** Spanish
ARB entries were compared with English; **12 values** were corrected or clarified.
“Clear all” in notifications now says **Eliminar todas**, accurately describing
deletion rather than clearing a selection. Reminder controls use **Tratamiento**
for tú/usted; payment grace-period terminology and the external-browser help are
clearer. Neutral `es` and the existing **tú** interface tone are preserved; a formal
outgoing reminder can still use **usted**. Keys, interpolation arguments and app
behavior are unchanged. Native permission/OAuth strings were reviewed and needed
no edits. Dart catalogs were regenerated and formatted; **227 tests pass** and
Flutter analysis reports **no issues**. Independent linguistic review and actual
device checks remain pending, especially notifications, reminder dialogs, large
text, accessibility and the external-browser flow. No agents, push, CI or release.
**No APK was rebuilt for either linguistic follow-up**; older artifacts below
do not contain these corrections. Future Android builds must retain **JDK 17**.

Linguistic review follow-up, **20 October 2026**, local only. All 609 entries in
each German/French ARB were compared with English. Corrected 215 German and 201
French values, including passkeys versus passwords, account/session terminology,
recovery, reply reminders, payment deadlines, and the reversed French meaning of
“Never remember this”. Generated Dart catalogs were regenerated. System permission
descriptions and Android OAuth labels were reviewed; their text did not require
changes. Formal Sie/vous, keys, interpolation parameters and application behavior
are preserved. This is model review; independent linguistic and real-device
validation remain pending. Fresh verification passed 227 Flutter tests and
analysis reported no issues; another 80 simulated login rendering cases passed
across five languages, Android/iOS, light/dark, 320/390 logical pixels and
100%/200% text. The iOS simulations use local fonts on Windows and do not qualify
native iOS typography or physical devices. No agents, push, CI or release.

**The APK listed below predates these linguistic corrections and has not been
rebuilt for this review.** Its hash and earlier test results remain historical.
Any subsequent Android build must keep the project’s JDK 17 procedure.

German/French follow-up, **20 October 2026**, local development only. The shared
app now includes Italian, English, neutral Spanish, standard German (`de`, formal
Sie) and standard French (`fr`, formal vous). Registry labels, ARB catalogs,
generated Dart delegates, Android locale/OAuth resources and iOS permission
descriptions/Xcode references cover all five languages. Language does not select
a number format, date order, currency or regional voice variant.

The full Flutter suite passed 227 tests; analysis reported no issues. Eighty
private login rendering cases passed across the five languages, simulated
Android/iOS, light/dark, 320/390 logical pixels and 100%/200% text. Native resource
contract tests check the actual Xcode variant group and bundle language list,
not just the existence of translated files. Simulated iOS uses local test fonts
on Windows; native macOS/iOS builds, real permission sheets, physical devices,
accessibility, background operation and offline speech still require validation.

The local APK is built with the project's JDK **17** procedure, warning-mode all
and native lint. Draft translations and local build success do not constitute
independent linguistic approval, Store availability or a production release.
Existing server-managed commercial content and issued documents are preserved;
new editorial language variants must be completed and approved separately.
The following Google-mark notes and their artifact describe the preceding build.

Previous local five-language debug APK (before this linguistic review):
`build/local/CercaPosta-Android-multilingua-local-jdk17-de-fr-20261020-reviewed.apk`,
**216381708 bytes**, SHA-256
`04a9ba9d1e2299c15018c543697e6eb10445b373b3794e86571d2b1b5faab8da`.
JDK 17.0.20.1+1, native lint **0 errors/0 warnings**, Android Debug signature
verified; compiled locale delegates and the three Flutter ABIs checked. No push,
CI, Store submission or release. Native iOS and real-device checks remain open.

Google mark follow-up, **20 October 2026**, local only. The shared iOS/Android
login now uses `assets/icons/google-sign-in.svg`, identical to the Desktop
asset and the four paths/colours in the Web component. `GoogleSignInMark` uses
a 16-logical-pixel box, preserves all four brand colours without a colour
filter and excludes the decorative SVG from semantics. The existing localized
button label, callback and busy/disabled gate remain in place. No dependency,
catalog or native permission change is required.

Fresh checks for this change: Flutter analysis has no issues; eight private
rendering checks verify all four colours in actual rendered pixels, SVG size,
absence of tint and layout exceptions. Cases cover simulated Android/iOS,
light/dark, Italian at 390 pixels with normal text and Spanish at 320 pixels
with 200% text. iOS simulation on Windows uses local test fonts; it does not
qualify native San Francisco metrics, an iOS build or a physical device.
The earlier test counts below belong to the preceding login update.

Previous Google-mark local debug APK:
`build/local/CercaPosta-Android-multilingua-local-jdk17-google-20261020.apk`,
**216273409 bytes**, SHA-256
`1412923c93c73f6cdfc02914b270e27f2e318e96ec960d41c48a2f9cf2ba1146`,
build ID `local-multilingua-google-20261020`. The shared runner used Eclipse
Temurin **17.0.20.1+1**, native LIFECYCLE logging with warning-mode all and lint
**0 errors/0 warnings**, followed by Flutter's complete successful APK postcheck.
Android Debug signing, all three Flutter ABIs, compiled IT/EN/ES and the exact
Google/CercaPosta/Apple/passkey SVG assets are verified in the APK itself.
Build evidence: `build/check-logs/google-20261020-01/`. Earlier APK copies remain
available. No device installation, push, CI run, Store submission or release.
Native iOS compilation on macOS and real-device icon, theme, accessibility and
sign-in checks remain pending.

Local login update, **20 October 2026**. The shared Android/iOS login now uses the
same CercaPosta SVG as the Web/Desktop, at 36 logical pixels, with the WpWeb logo
at 56 pixels on the right. The localized heading is 16 pixels/weight 600 and its
subtitle is 12 pixels/weight 400; both wrap and respect the device text scale.
The existing system sans-serif family remains in use (Roboto/SF according to the
platform); no font download or dependency was added. IT/EN/ES use the exact Web
heading/tagline in two new ARB messages.

The passkey mark is 17 pixels and shares the Web/Desktop muted colour:
`#5c6670` in light mode, `#9aa4ae` in dark mode. Apple uses the same SVG path and
20-pixel box as Web/Desktop. Alternative sign-in buttons use an outlined style,
retain their existing callbacks and disabled gates, and have a 44-pixel minimum
height that can grow with larger text. The fingerprint for device biometrics
remains separate from the passkey icon.

Fresh checks: clean Flutter analysis; two localization-contract tests and three
passkey-policy tests pass. A private local harness checks the actual LoginScreen
in **48 combinations**: simulated Android/iOS, IT/EN/ES, light/dark, 320/390-pixel
widths, normal/200% text. Heading styles, passkey tint, SVG sizes, scrolling to
Apple, button semantics and absence of layout exceptions pass. These widget
simulations do not replace native iOS compilation or tests on physical devices.

Previous local debug APK (login layout): `build/local/CercaPosta-Android-multilingua-local-jdk17-login-20261020.apk`,
**216273298 bytes**, SHA-256 `f8a8eae3048de7c442f9407883dcd6c2def0e9895f4b6f167643410471ed73ec`,
build ID `local-multilingua-login-20261020`. The shared runner used Eclipse Temurin
**17.0.20.1+1**, native LIFECYCLE logging with warning-mode all and lint
**0 errors/0 warnings**, followed by Flutter's complete successful APK postcheck.
Android Debug signing, the three Flutter ABIs, compiled IT/EN/ES and exact SVG
matches for CercaPosta/Apple/passkey are verified in the APK itself. Complete
build evidence is in `build/check-logs/login-20261020-01/`. Previous APK copies are
preserved. No device installation, push, CI run, Store submission or release.
Native iOS build on macOS and real-device login, theme, scaling, keyboard and
accessibility checks still remain.

The measurements below describe the earlier October 18 qualification.

Earlier Android build/CI follow-up (18 October 2026): the [shared JDK 17 runner](android-build-logging.md)
now performs config-only preparation, native compilation/lint with all warnings
visible and Flutter's complete postcheck. Both Android jobs use it in the locally
edited workflow. **60 tool tests pass**, including real Gradle logging/failure
regressions; YAML/pins and 31 Bash blocks validate locally. The debug APK remains
byte-identical after rebuilding, lint stays **0 errors/0 warnings** with the six
intentional exceptions. No push, remote CI run, release or device installation.
The release QA runner also passes with synthetic signing and the full Flutter
postcheck: all 569 non-signature bundle entries match the preceding QA bundle.
The temporary key is removed. This is ARM64 QA, not an all-ABI release or Store
qualification. R8 is up-to-date here; its preceding forced execution remains
historical evidence. The earlier SDK/log measurements below remain historical.

Local development update: 18 October 2026. Spanish uses the neutral application code `es`. These source changes and local test builds have not been released to either Store.

`assets/l10n/languages.json` declares supported language codes, native labels and an explicit `flag` reference for the shared login selector. Flags are presentation metadata and do not set regional formats or the neutral Spanish variant. `lib/core/language_registry.dart`, Flutter supported locales and the native Android/iOS declarations must agree. Each language needs a complete authored ARB catalog; generated Dart fallback text does not count as a translation. `test/localization_contract_test.dart` checks keys, interpolation arguments and flag references without depending on a private repository.

The device interface language, the server profile language for email, receipts and AI responses, numeric/date formats and the preferred regional voice locale are separate choices. Updating a profile includes its expected previous language. Opening or refreshing a profile does not overwrite a device's explicit interface preference. Billing summaries and plan-change summaries request interface-language content and retain the legacy IT/EN fields for compatibility; missing commercial Spanish text falls back to English.

Voice recognition stays on the device. An explicit available regional voice preference takes precedence, followed by an exact available device locale matching the interface language. Otherwise the user chooses among candidates. The app never silently chooses Spain or a Latin American region. Missing recognition support returns to keyboard input; it does not switch to a remote recognizer. Android 13+ enumerates installed local recognition languages; Android 12 cannot enumerate them and only tries the exact device locale locally. iOS candidates must report on-device recognition support. Availability still needs testing on actual devices.

Earlier local checks completed: Flutter static analysis without issues, 227 tests passing, all 607 current ARB messages authored in Spanish, native permission strings and Android OAuth labels present. A Spanish billing layout with a long plan name passes on a narrow viewport with 200% text scaling. These checks do not cover every screen or constitute independent linguistic review.

The current Android APK uses Eclipse Temurin **17.0.20.1+1** (CI semver **17.0.20+101**), **Gradle 8.14.6, AGP 8.13.2, KGP/stdlib 2.3.21 and bundled R8 8.13.19**. Flutter 3.32.3/Dart 3.8.1, SDK 23/36/36, NDK 27, Build Tools 35 and desugaring 2.1.5 remain unchanged. The original JDK archive checksum remains verified. The [native compatibility follow-up](android-native-compat.md) records 25 components/53 reviewed source patches applied to build copies, with the original Pub/Flutter sources preserved. Four Flutter source hashes also match the official tag. Command-line tools 23 read the global SDK; AGP builds use an isolated SDK whose same platform 36 revision 2 is registered with official tools 19 and compatible XML metadata. JDK 17 is explicit for the launcher and daemon using process-local settings; global Java/Flutter preferences remain unchanged. The [earlier toolchain qualification](android-toolchain.md) is historical evidence for the compiler alignment.

The [latest SDK/logging follow-up](android-build-logging.md) preserves JDK 17 and compiled app contents. The isolated build SDK now has authentic Google-installer registration for command-line tools 19/23: all 247 tool files match; 263 tool/build inputs remain identical; eight metadata files validate. SDK verbose inspection has no legacy/XML messages. Gradle LIFECYCLE with warning-mode all removes INFO from ordinary output while keeping warnings/errors visible; Flutter verbose remains available for diagnosis. A quiet Flutter build alone is not used as proof of native warning visibility. Native lint succeeds in **1m56s**, 969 tasks (13 executed/956 up-to-date), **0 errors/0 warnings**, the same six intentional exceptions. All **47 tool tests pass**: SDK/log/workflow/loader/JDK/resource/signature/Java **13/8/6/6/2/3/8/1**. Three logging and three R8 options cases pass separately. The earlier 227 Flutter tests and clean analysis are historical evidence, not rerun counts for this SDK/log-only change.

The former **1851 D8 Kotlin-metadata warnings remain absent**. The new ARM64 QA native build actually reruns R8 at LIFECYCLE: **3m59s**, 893 tasks (43 executed/850 up-to-date), followed by the ordinary Flutter command and full postcheck (Gradle phase 136.9s). Both pass the diagnostic gate without the residual messages. The synthetic signature is verified and the temporary key removed, with no real upload key. All **569 unsigned bundle entries are byte-identical** to the preceding QA, including code, manifest, libraries, fonts/resources, metadata and mapping. Only signature entries differ. This private QA bundle is not a Store deliverable or all-ABI release qualification. See [logging policy](android-build-logging.md), [lint](android-lint.md) and [native compatibility](android-native-compat.md) for source evidence and limits.

The preceding JDK-17 run had already fixed four splash `NewApi` errors: API-specific attributes were in the base API-23 themes. Cutout settings now live in `values[-night]-v28`, and Force Dark settings in `values[-night]-v29`, with the light/dark appearance and API-31 themes preserved. The warning audit additionally deduplicates identical splash PNGs using an alias, relocates constant background bitmaps to `nodpi`, retains the dynamically looked-up notification icon and explicitly excludes cloud backup/device transfer. The resource merger initially retained a stale missing-resource result after removing API-21 duplicates; regenerating only its intermediate cache resolved it without source changes. No minSdk increase. Follow the regeneration instructions in the quality audit after running the splash generator.

At the end of the 18 October qualification, the debug APK was `build/local/CercaPosta-Android-multilingua-local-jdk17-lintfix-20261018.apk`, **189763328 bytes**, SHA-256 `ec8ce241345d018236fdd53cfc0bd025cd5d06b32f880b270e8a9a2cb882c606`, build ID `local-multilingua-20261018-lintfix`. Android Debug signature, compiled IT/EN/ES, three Flutter ABIs, native locales, splash/notification resources and 18 backup exclusions are verified. All 533 Android resource entries, 16 other asset entries, eight native libraries, the manifest and every DEX are byte-identical to nativefix; only the kernel and three signing entries differ, among the same 660 entries. No Dart UI source was changed; differing build ID lengths prevent claiming kernel identity by simple string replacement. The SDK/log-only follow-up rechecks this same APK in all three output/copy locations; no new debug artifact/version is needed. The previous nativefix/toolchain/warningfix APKs and reports remain historical. All 53 original patched inputs, pubspec/lock and ten source PNGs are preserved. No device installation, commit, push or publication occurred. Windows cannot validate a native iOS build.

The [native follow-up](android-native-compat.md) records the original compiler/SDK fixes. The [SDK/logging study](android-build-logging.md) removes the SDK legacy cause without changing binaries. Flutter's Inspector trace and the 23 R8 INFO lines remain available at verbose/info levels; ordinary native quality builds use LIFECYCLE with warnings enabled. No output filter, font change, custom handler, vendor bytecode patch or blanket Proguard suppression is introduced. Real missing-font diagnostics remain in the gate; retain full diagnostic logs when qualifying fonts/toolchain/plugins/new languages. Local success does not certify devices, real upload signing or Store submission.

Real-device checks still required: Spanish UI and system language switching/persistence, complete login/archive flows, biometrics, local notifications/background execution, permission text, attachment sharing/previews, small screens/tablets, keyboard, large text, TalkBack/VoiceOver and local voice availability in airplane mode. Check both missing models and denied permissions without a cloud fallback. On iOS also build on macOS and verify Dynamic Type, native permission dialogs and iPad layout. Keep numeric/date settings and the server profile language for email, receipts and AI separate from device UI language. Debug signatures cannot replace an installation signed with a different key; use a compatible test device/profile.

To add another language, update the public registry including its flag reference and all generated/native declarations, provide the corresponding login flag resource in the Web client, author the ARB catalog, run the localization generator, format/analyze/test, compile both native clients and review narrow screens, large text, accessibility and local voice availability. Storage units retain the [existing product contract](storage-units.md).
