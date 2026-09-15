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

    def test_server_checkout_is_pinned_and_mandatory(self):
        steps = self.jobs["backend-compatibility"]["steps"]
        checkout = next(step for step in steps if step.get("with", {}).get("repository") == "wpwebsrl/cercaposta")
        self.assertEqual(checkout["with"]["ref"], "${{ vars.BACKEND_COMPAT_REF }}")
        self.assertEqual(checkout["with"]["persist-credentials"], "false")
        self.assertIn("--require-source --expected-commit", str(steps))
        self.assertNotIn("continue-on-error", str(steps))


if __name__ == "__main__":
    unittest.main()
