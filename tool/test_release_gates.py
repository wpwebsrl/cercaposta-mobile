"""Release dispatch must use the same revision's quality and compatibility gates."""
from copy import deepcopy
from pathlib import Path
import unittest
import yaml

WORKFLOW = Path(__file__).resolve().parents[1] / ".github/workflows/mobile.yml"


def requires_success(job, required):
    if not set(required) <= set(job.get("needs", [])):
        raise AssertionError("Release is missing required quality gates")
    if any(word in job.get("if", "") for word in ("always()", "failure()", "cancelled()")):
        raise AssertionError("Release must preserve Actions' implicit success() condition")
    if job.get("continue-on-error") == "true":
        raise AssertionError("Release failure cannot be ignored")


class ReleaseGates(unittest.TestCase):
    def setUp(self):
        self.jobs = yaml.load(WORKFLOW.read_text(encoding="utf-8"), Loader=yaml.BaseLoader)["jobs"]

    def test_both_dispatch_platforms_require_tests(self):
        for name in ("release-ios", "release-android"):
            requires_success(self.jobs[name], ["analyze-test-android", "backend-compatibility"])
        requires_success(self.jobs["release-ios"], ["build-ios-check"])
        self.assertNotIn("if", self.jobs["analyze-test-android"])
        self.assertNotIn("if", self.jobs["build-ios-check"])

    def test_failed_or_skipped_test_cannot_be_ignored(self):
        for name in ("release-ios", "release-android"):
            for fault in ("missing", "always"):
                job = deepcopy(self.jobs[name])
                if fault == "missing": job["needs"].remove("analyze-test-android")
                else: job["if"] = "always() && (" + job["if"] + ")"
                with self.subTest(name=name, fault=fault), self.assertRaises(AssertionError):
                    requires_success(job, ["analyze-test-android"])

    def test_android_quality_gate_requires_native_lint(self):
        steps = self.jobs["analyze-test-android"]["steps"]
        lint = next(step for step in steps if "build_android.py --variant debug" in step.get("run", ""))
        self.assertIn("--lint", lint["run"])
        self.assertNotIn("if", lint)
        self.assertNotIn("continue-on-error", lint)

    def test_server_checkout_is_pinned_and_mandatory(self):
        steps = self.jobs["backend-compatibility"]["steps"]
        checkout = next(step for step in steps if step.get("with", {}).get("repository") == "wpwebsrl/cercaposta")
        self.assertEqual(checkout["with"]["ref"], "${{ vars.BACKEND_COMPAT_REF }}")
        self.assertEqual(checkout["with"]["persist-credentials"], "false")
        self.assertIn("--require-source --expected-commit", str(steps))
        self.assertNotIn("continue-on-error", str(steps))

    def test_android_build_and_lint_require_compiler_diagnostic_gate(self):
        for job, command in (("analyze-test-android", "build_android.py --variant debug"),
                             ("release-android", "build_android.py --variant release")):
            steps = self.jobs[job]["steps"]
            step = next(s for s in steps if command in s.get("run", ""))
            with self.subTest(command=command):
                self.assertEqual(step.get("shell"), "bash")
                # The shared Python runner tees output, checks child status and
                # diagnostics itself. No shell pipeline may mask its exit code.
                self.assertNotIn("|", step["run"])
                for argument in ('--java-home "$JAVA_HOME"', '--flutter-sdk "$FLUTTER_ROOT"',
                                 '--android-sdk "$ANDROID_HOME"', '--log-dir "$RUNNER_TEMP/'):
                    self.assertIn(argument, step["run"])
                self.assertNotIn("if", step)
                self.assertNotIn("continue-on-error", step)

    def test_android_jobs_prepare_isolated_sdk_and_select_jdk17(self):
        for name in ("analyze-test-android", "release-android"):
            steps = self.jobs[name]["steps"]
            preparation = next(s for s in steps if "prepare_android_sdk17.py" in s.get("run", ""))
            with self.subTest(job=name):
                self.assertNotIn("if", preparation)
                self.assertNotIn("continue-on-error", preparation)
                self.assertIn('"$JAVA_HOME"', preparation["run"])
                self.assertIn('"$RUNNER_TEMP/cercaposta-sdk17"', preparation["run"])
                java = next(s for s in steps if s.get("uses", "").startswith("actions/setup-java@"))
                self.assertEqual(java["with"]["java-version"], "17.0.20+101")
                self.assertEqual(java["with"]["distribution"], "temurin")

    def test_build_regressions_run_before_debug_compilation(self):
        steps = self.jobs["analyze-test-android"]["steps"]
        tests = next(i for i, s in enumerate(steps) if "-p test_build_android.py" in s.get("run", ""))
        compilation = next(i for i, s in enumerate(steps) if "build_android.py --variant debug" in s.get("run", ""))
        self.assertLess(tests, compilation)
        self.assertNotIn("if", steps[tests])
        visibility = next(s for s in steps if "-p test_android_logging.py" in s.get("run", ""))
        self.assertNotIn("if", visibility)
        self.assertNotIn("continue-on-error", visibility)

    def test_android_diagnostics_survive_failure_without_promoting_failed_build(self):
        for name, variant in (("analyze-test-android", "debug"), ("release-android", "release")):
            steps = self.jobs[name]["steps"]
            diagnostics = next(s for s in steps if s.get("with", {}).get("name", "").startswith(f"android-{variant}-diagnostics"))
            self.assertEqual(diagnostics["if"], "always()")
            self.assertIn(f"cercaposta-android-{variant}", diagnostics["with"]["path"])
            self.assertNotIn("continue-on-error", diagnostics)
        release = self.jobs["release-android"]["steps"]
        bundle = next(s for s in release if s.get("with", {}).get("name") == "app-release-aab")
        self.assertNotIn("if", bundle)  # default success(); never always()
        self.assertIn("verify_android_artifact.py", str(release))
        self.assertIn("steps.bn.outputs.num", str(release))


if __name__ == "__main__":
    unittest.main()
