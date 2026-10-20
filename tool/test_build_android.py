"""Protect native warning visibility, build-input parity and fail-closed sequencing."""
import base64
from contextlib import contextmanager
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import build_android as builder


class AndroidBuilder(unittest.TestCase):
    def arguments(self, variant="debug", *extra):
        return builder.parser().parse_args([
            "--java-home", "jdk", "--flutter-sdk", "flutter", "--android-sdk", "sdk",
            "--variant", variant, "--app-build", "local-test", "--app-build-date", "2026-10-18",
            "--log-dir", "logs", *extra])

    def test_debug_uses_three_abis_and_flutter_effective_icon_flag(self):
        common, native = builder.build_arguments(self.arguments(), ["FLUTTER_VERSION=3.32.3"])
        self.assertIn("--target-platform=android-arm,android-arm64,android-x64", common)
        self.assertIn("-Ptree-shake-icons=false", native)  # Flutter disables it in debug
        self.assertIn("-Ptarget=" + str(Path("lib/main.dart")), native)
        self.assertIn("-Pdart-obfuscation=false", native)
        encoded = next(p.split("=", 1)[1] for p in native if p.startswith("-Pdart-defines="))
        self.assertEqual([base64.b64decode(d).decode() for d in encoded.split(",")],
                         ["APP_BUILD=local-test", "APP_BUILD_DATE=2026-10-18", "FLUTTER_VERSION=3.32.3"])

    def test_release_preserves_obfuscation_symbols_version_and_unicode_defines(self):
        args = self.arguments("release", "--build-number", "123", "--build-name", "1.6.0",
                              "--target-platform", "android-arm64", "--split-debug-info", "symbols with spaces",
                              "--dart-define", "LABEL=Español, café = sí")
        common, native = builder.build_arguments(args, [])
        self.assertIn("--build-number=123", common)
        self.assertIn("--build-name=1.6.0", common)
        self.assertIn("--obfuscate", common)
        self.assertIn("-Pdart-obfuscation=true", native)
        self.assertIn("-Ptree-shake-icons=true", native)
        path = next(p.removeprefix("--split-debug-info=") for p in common if p.startswith("--split-debug-info="))
        self.assertIn("-Psplit-debug-info=" + path, native)
        encoded = next(p.split("=", 1)[1] for p in native if p.startswith("-Pdart-defines="))
        self.assertEqual(base64.b64decode(encoded.split(",")[-1]).decode(), "LABEL=Español, café = sí")

    def test_unknown_modes_platforms_and_flags_are_rejected(self):
        for variant in ("profile", "unknown"):
            with self.subTest(variant=variant), patch("sys.stderr", new_callable=io.StringIO), self.assertRaises(SystemExit):
                self.arguments(variant)
        for extra in (("--target-platform", "android-x86"), ("--target-platform", "android-arm,android-arm"),
                      ("--build-number", "0"), ("--app-build-date", "invalid"),
                      ("--dart-define", "FLUTTER_VERSION=other"), ("--dart-define", "APP_BUILD=other"),
                      ("--dart-define", "missing-equals"), ("--split-debug-info", "symbols")):
            with self.subTest(extra=extra), self.assertRaises(ValueError):
                builder.build_arguments(self.arguments("debug", *extra), [])

    def test_tool_upgrade_requires_adapter_review(self):
        version = {"frameworkVersion": "3.32.3", "dartSdkVersion": "3.8.1", "channel": "stable",
                   "repositoryUrl": "https://github.com/flutter/flutter.git",
                   "frameworkRevision": "5c1433509f997e", "engineRevision": "31c4875c7aa007"}
        with patch.object(Path, "read_text", return_value=json.dumps(version)):
            defines = builder.framework_defines(Path("flutter"))
        self.assertIn("FLUTTER_FRAMEWORK_REVISION=5c1433509f", defines)
        self.assertIn("FLUTTER_ENGINE_REVISION=31c4875c7a", defines)
        for key in ("frameworkVersion", "dartSdkVersion", "channel"):
            changed = dict(version, **{key: "changed"})
            with self.subTest(key=key), patch.object(Path, "read_text", return_value=json.dumps(changed)), self.assertRaises(ValueError):
                builder.framework_defines(Path("flutter"))

    def test_stream_retains_stdout_stderr_and_nonzero_exit(self):
        class Console:
            buffer = io.BytesIO()
        with tempfile.TemporaryDirectory() as folder, patch("sys.stdout", Console()):
            log = Path(folder) / "fixture.log"
            code = builder.stream([sys.executable, "-c", "import sys; print('native warning', flush=True); print('native error', file=sys.stderr, flush=True); sys.exit(7)"],
                                  Path(folder), dict(os.environ), log)
            self.assertEqual(code, 7)
            self.assertEqual(Console.buffer.getvalue(), log.read_bytes())
            self.assertIn(b"native warning", log.read_bytes())
            self.assertIn(b"native error", log.read_bytes())
            with self.assertRaises(FileExistsError):
                builder.stream([], Path(folder), {}, log)

    def test_step_rejects_failure_missing_completion_and_compiler_diagnostic(self):
        for code, output in ((2, "BUILD SUCCESSFUL"), (0, "unfinished"),
                             (0, "BUILD SUCCESSFUL\nWARNING: D8: broken metadata"),
                             (0, "BUILD SUCCESSFUL\nBUILD FAILED")):
            with tempfile.TemporaryDirectory() as folder:
                log = Path(folder) / "native.log"
                def stream(*_):
                    log.write_text(output)
                    return code
                with self.subTest(code=code, output=output), patch.object(builder, "stream", side_effect=stream), self.assertRaises(RuntimeError):
                    builder.step([], Path(folder), {}, log, "BUILD SUCCESSFUL")

    def exercise(self, variant, failure=None, native_info=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            args = self.arguments(variant, *(["--lint"] if variant == "debug" else []),
                                  *(["--native-info"] if native_info else []))
            args.log_dir = root / "evidence"
            args.android_sdk = root / "sdk"
            args.android_sdk.mkdir()
            (args.android_sdk / "cercaposta-build-sdk.json").write_text('{"state":"verified"}')
            artifact = root / ("build/app/outputs/bundle/release/app-release.aab" if variant == "release"
                               else "build/app/outputs/flutter-apk/app-debug.apk")
            artifact.parent.mkdir(parents=True)
            artifact.write_bytes(b"fixture, not an installable artifact")
            calls = []
            @contextmanager
            def environment(*_):
                yield {"JAVA_HOME": "jdk17", "ANDROID_HOME": str(args.android_sdk)}
            def step(command, cwd, env, log, completion):
                calls.append((command, cwd, env, log.name))
                log.write_text("unfiltered fixture output")
                if failure == log.name:
                    raise RuntimeError("expected stage failure")
            with patch.object(builder, "ROOT", root), patch.object(Path, "cwd", return_value=root), \
                 patch.object(builder, "framework_defines", return_value=[]), patch.object(builder, "validate_metadata"), \
                 patch.object(builder, "environment", environment), patch.object(builder, "step", side_effect=step), \
                 patch.dict(os.environ, {"ANDROID_UPLOAD_CERT_SHA256": "a" * 64}), patch("sys.stdout", new_callable=io.StringIO):
                if failure:
                    with self.assertRaises(RuntimeError):
                        builder.build(args)
                else:
                    builder.build(args)
                    with self.assertRaises(FileExistsError):
                        builder.build(args)  # never overwrite evidence
            report = json.loads((args.log_dir / "result.json").read_text())
            self.assertEqual(report["state"], "failed" if failure else "passed")
            self.assertFalse(report["published"])
            return calls, report

    def test_debug_config_native_lint_then_full_flutter_postcheck(self):
        calls, report = self.exercise("debug")
        self.assertEqual([c[3] for c in calls], ["configuration.log", "sdk-paths.log", "native.log", "flutter.log"])
        self.assertIn("--config-only", calls[0][0])
        self.assertNotIn("--no-pub", calls[0][0])
        native = calls[2][0]
        for flag in (":app:assembleDebug", ":app:lintDebug", "-Dorg.gradle.logging.level=lifecycle", "--warning-mode=all", "--console=plain"):
            self.assertIn(flag, native)
        self.assertNotIn("-q", native)
        self.assertNotIn("--info", native)
        postcheck = calls[3][0]
        self.assertEqual(postcheck[-1], "--dart-define=APP_BUILD_DATE=2026-10-18")
        self.assertNotIn("--config-only", postcheck)
        self.assertIn("apk", postcheck)
        self.assertEqual(calls[0][0][calls[0][0].index("--debug"):], postcheck[postcheck.index("--debug"):])

    def test_release_uses_bundle_and_mandatory_final_signature_check(self):
        calls, report = self.exercise("release")
        self.assertIn("apk", calls[0][0])  # official config-only preparation
        self.assertIn(":app:bundleRelease", calls[2][0])
        self.assertNotIn(":app:assembleDebug", calls[2][0])
        self.assertIn("appbundle", calls[3][0])
        self.assertIn("--obfuscate", calls[3][0])
        self.assertEqual(calls[-1][3], "signature.log")

    def test_each_failed_stage_stops_subsequent_steps(self):
        stages = ["configuration.log", "sdk-paths.log", "native.log", "flutter.log", "signature.log"]
        for index, stage in enumerate(stages):
            with self.subTest(stage=stage):
                calls, _ = self.exercise("release", stage)
                self.assertEqual([c[3] for c in calls], stages[:index + 1])

    def test_info_mode_keeps_warning_mode_all(self):
        calls, report = self.exercise("debug", native_info=True)
        self.assertIn("--info", calls[2][0])
        self.assertIn("--warning-mode=all", calls[2][0])
        self.assertEqual(report["native_log_level"], "INFO")


if __name__ == "__main__":
    unittest.main()
