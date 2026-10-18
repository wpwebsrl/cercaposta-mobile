# Android native resources and lint

The latest [lint/INFO qualification](android-lint.md) uses Gradle 8.14.6/JDK 17 and reports **0 errors/0 warnings**, with six explicit intentional exceptions and unchanged artwork/SDK support. It identifies the current lintfix APK. The [native follow-up](android-native-compat.md) resolved the earlier emitted deprecations/XML warning. The inventories and seven-warning nativefix snapshot below are historical resource/native audits.

Local audit: 18 October 2026. These changes have not been released. The
[localization status](localization.md) identifies the current debug APK and checks.

The original resource audit completed offline with JDK 17: **0 errors, 6 warnings**,
down from 19. The remaining findings are one `localeConfig` advisory and five
`IconLauncherShape` advisories. Two resource-policy tests and four release-gate
tests pass. The app native unit task has no sources; no device tests were run.

The subsequent [toolchain upgrade](android-toolchain.md) resolves the D8/Kotlin
compiler mismatch and repeats Flutter/debug/R8 checks. Current lint is **0 errors,
7 warnings**: the same six resource advisories plus a newer-Gradle notice. The
original counts below describe the earlier resource-only audit. The current APK,
hashes and test results are in the localization status linked above.

## Corrections to the original 19 lint warnings

| Lint ID | Original instances | Action |
|---|---:|---|
| `GradleDependency` | 1 | Pin `desugar_jdk_libs` to 2.1.5 instead of 2.1.4. No change to Flutter, Gradle, AGP, Kotlin, minSdk or the build JDK. |
| `DataExtractionRules` | 1 | Add explicit exclusions for every data domain in both cloud backup and device transfer; retain `allowBackup=false` and explicitly set `fullBackupContent=false`. |
| `ObsoleteSdkInt` | 2 | Remove byte-identical `drawable-v21` and `drawable-night-v21` resources; the minimum supported API is already 23. |
| `UnusedResources` | 1 | Keep the real notification icon using a package-specific `tools:keep` rule. Flutter resolves this resource by name through a method channel. |
| `IconDuplicatesConfig` | 2 | Remove the two identical copies of the background bitmap for API 21. |
| `IconLocation` | 1 | Move both original one-pixel background bitmaps to `drawable-nodpi` and `drawable-night-nodpi`, preserving bytes and resource names. |
| `IconDuplicates` | 5 | Keep one original splash PNG per density and alias `android12splash` to `splash`. Day/night PNGs had identical SHA-256 values. The dark background remains separate. |
| `UnusedAttribute` (`localeConfig`) | 1 | Retain the manifest declaration needed for the system language picker on Android 13+. Older Android versions use the Flutter language selection. |
| `IconLauncherShape` | 5 | Retain the current white-background legacy launcher artwork in all five densities. Removing these advisories would require changing its appearance. Android 8+ already has an adaptive icon with foreground inset and system masking. |

The 13 corrected original instances concern real configuration, an explicit dependency
update or provably redundant resources. No lint baseline, blanket suppression or
minimum-SDK increase was introduced. The original 20 removed files were compared
using complete-file SHA-256 values before removal; launcher artwork was untouched.

Google's [desugaring changelog](https://github.com/google/desugar_jdk_libs/blob/master/CHANGELOG.md)
lists the 2.1.5 change and the AGP 8.0+ requirement for the 2.1 series; this project
used AGP 8.9.1 during that resource audit (now 8.13.2 after qualification). The patch adds support for `Stream.toList()` without requiring an
application API migration.

## Backup policy and real-device checks

The application already disables backup because local state can contain sensitive
information. The new XML completes this policy for standard Android 12+ cloud and
device-transfer mechanisms. All nine credential-protected, device-protected and
external domains are explicitly excluded in each transport; no include rule
re-enables them. A new device must authenticate and rebuild its local state.
Existing on-device data is not deleted.

Android documents that [allowBackup=false alone can leave OEM device transfers enabled](https://developer.android.com/identity/data/autobackup#EnablingAutoBackup).
The exclusions express the intended policy; device/OEM behavior still needs a
controlled transfer test with synthetic data. Check that sessions, secure preferences,
databases and caches do not migrate. This audit does not opt into cross-platform
transfer or validate third-party migration tools.

`tool/test_android_resources.py` checks both transports and the legacy manifest
opt-out, plus retention of the icon actually named by `NotifyService`. The quality
workflow runs these tests and native lint. Its configuration was edited locally;
no remote workflow was triggered.

## Generated splash resources

The deduplication preserves both logical drawable names, all five density variants,
the foreground pixels and light/dark colors. Native build and AAPT checks validate
the compiled references. Still check cold start on Android 6/7, Android 8–11 and
Android 12+, light/dark modes and multiple display densities. Check launcher
appearance on both legacy and adaptive launchers and send a local test notification.

After `dart run flutter_native_splash:create`:

1. Preserve the API-28 cutout and API-29 Force Dark theme overrides. These
   attributes must not return to the base API-23 themes.
2. Inspect regenerated image hashes before deduplicating. If day/night or Android-12
   artwork now differs, preserve distinct resources; never alias different images.
3. For identical artwork, retain the canonical density PNGs and the existing
   `values/splash_aliases.xml` alias; remove generated copies with the same resource
   name as the alias to avoid an AAPT duplicate-definition error.
4. Put the constant background bitmaps in the `nodpi` folders and remove obsolete
   API-21 copies only after confirming identical content. Keep the notification icon
   and `raw/keep_it_cercaposta_app.xml`.
5. Run the resource-policy tests and `:app:assembleDebug :app:lintDebug` with JDK 17.
   Inspect the lint report, compiled resource table and the real splash screens.

The [resource keep rules](https://developer.android.com/topic/performance/app-optimization/customize-which-resources-to-keep)
protect runtime name lookups. Android also supports
[resource aliases](https://developer.android.com/guide/topics/resources/providing-resources#AliasResources)
and [adaptive launcher icons](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive).
The five legacy-icon advisories remain visible so a future graphic review can
address them explicitly rather than silently changing the brand assets.
