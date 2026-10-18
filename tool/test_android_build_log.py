"""Regressions for previously non-fatal Android compiler compatibility diagnostics."""
import unittest

from check_android_build_log import check


class AndroidBuildLog(unittest.TestCase):
    def test_old_d8_metadata_warning_is_rejected_even_with_successful_build(self):
        log = """> Task :app:mergeExtDexDebug
WARNING: D8: Unexpected error during rewriting of Kotlin metadata for class 'kotlin.Unit':
com.android.tools.r8.internal.Yu0: Should never be called
BUILD SUCCESSFUL in 1m
"""
        self.assertEqual(len(check(log)), 1)

    def test_release_r8_warning_is_also_rejected(self):
        self.assertTrue(check("WARNING: R8: Missing class example.External\r\nBUILD SUCCESSFUL"))

    def test_real_missing_fonts_are_distinguished_from_tool_information(self):
        self.assertTrue(check("Expected to find fonts for {CustomFont}, but found {}.\nBUILD SUCCESSFUL"))
        for line in (
            "Expected to find fontFamily for constant IconData with codepoint: 128842, but found fontFamily: null.",
            "INFO: R8: Proguard configuration rule does not match anything",
            "INFO: R8: InnerClasses attribute has entries missing a corresponding EnclosingMethod attribute.",
            "Parsing legacy package: isolated-sdk/cmdline-tools/19.0",
        ):
            with self.subTest(line=line):
                self.assertEqual(check(line + "\nBUILD SUCCESSFUL"), [])

    def test_incompatible_kotlin_dependency_is_rejected(self):
        self.assertTrue(check("e: Module was compiled with an incompatible version of Kotlin."))
        self.assertTrue(check("The Kotlin Gradle plugin was loaded multiple times in different subprojects"))

    def test_lint_advisories_are_not_hidden(self):
        log = """Warning: Launcher icons should not fill every pixel [IconLauncherShape]
BUILD SUCCESSFUL in 1m
"""
        self.assertEqual(check(log), [])

    def test_cross_drive_kotlin_cache_failure_is_rejected(self):
        log = """Kotlin daemon compilation failed
Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:/cache/Plugin.kt and E:/project/android.
BUILD SUCCESSFUL
"""
        self.assertEqual(len(check(log)), 1)

    def test_flutter_postcheck_failure_is_rejected_after_gradle_success(self):
        log = """BUILD SUCCESSFUL in 1m
Release app bundle failed to strip debug symbols from native libraries.
"""
        self.assertEqual(len(check(log)), 1)

    def test_sdk_schema_and_native_deprecations_are_rejected(self):
        for line in (
            "Warning: This version only understands SDK XML versions up to 3 but version 4 was encountered.",
            "Setting the namespace via the package attribute in the source AndroidManifest.xml is no longer supported",
            "Properties should be assigned using the 'propName = value' syntax.",
            "The CopyProcessingSpec.setFileMode(Integer) method has been deprecated.",
            "w: file:///plugin/Native.kt:10 Unnecessary safe call",
            "Note: Native.java uses or overrides a deprecated API.",
            "Note: Some input files use or override a deprecated API.",
            "w: Old plugin API is deprecated.",
            "WARNING: A restricted method in java.lang.System has been called",
            "Invocation of Task.project at execution time has been deprecated.",
            "Deprecated Gradle features were used in this build.",
        ):
            with self.subTest(line=line):
                self.assertTrue(check(line + "\nBUILD SUCCESSFUL"))


if __name__ == "__main__":
    unittest.main()
