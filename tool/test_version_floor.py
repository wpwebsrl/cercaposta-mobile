"""Compatibility release checks cannot silently fall back or ignore feature changes."""
import json
import subprocess
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

import check_version_floor as guard

SOURCE = 'AUTH_BREAKING: dict = {"ios": (("1.0.0", "baseline"),), "android": (("1.0.0", "baseline"),)}\nFEATURE_BREAKING: dict = {"ios": (("1.5.0", "feature"),), "android": (("1.6.0", "feature"),)}'


class VersionFloor(unittest.TestCase):
    def test_reads_auth_and_feature_floors(self):
        self.assertEqual(guard.floor_for(SOURCE, "ios"), "1.5.0")
        self.assertEqual(guard.floor_for(SOURCE, "android"), "1.6.0")
        self.assertEqual(guard.floor_for(SOURCE.replace('"1.0.0"', '"2.0.0"'), "ios"), "2.0.0")

    def test_missing_or_executable_registry_fails(self):
        for source in (SOURCE.split("FEATURE_BREAKING")[0], SOURCE.replace('{"ios":', 'dict(ios='),
                       'AUTH_BREAKING: dict = __import__("os").getcwd()'):
            with self.subTest(source=source), self.assertRaises((ValueError, SyntaxError)):
                guard.floor_for(source, "ios")

    def test_malformed_versions_are_not_silently_zero(self):
        for value in ("1", "1.2", "01.2.3", "1.2.3-rc1", "x.2.3", "1.2.3.4"):
            with self.subTest(value=value), self.assertRaises(ValueError): guard.parse_semver(value)
        self.assertEqual(guard.parse_semver("1.5.0+1"), (1, 5, 0))

    def test_release_cannot_use_snapshot_when_source_or_sha_missing(self):
        for args in (["--require-source"], ["--require-source", "--expected-commit", "main"],
                     ["--require-source", "--source", "missing", "--expected-commit", "a" * 40]):
            with self.subTest(args=args), self.assertRaises((ValueError, OSError, subprocess.CalledProcessError)):
                guard.main(args)

    def test_lower_client_fails_and_current_client_passes(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "compat.py"; source.write_text(SOURCE, encoding="utf-8")
            pubspec = root / "pubspec.yaml"; pubspec.write_text("version: 1.5.0+1\n", encoding="utf-8")
            with patch.object(guard, "MOBILE", root):
                with self.assertRaises(ValueError): guard.main(["--source", str(source)])
                pubspec.write_text("version: 1.6.0+1\n", encoding="utf-8")
                self.assertEqual(guard.main(["--source", str(source)]), 0)

    def test_wrong_revision_and_dirty_registry_fail(self):
        with TemporaryDirectory() as directory:
            source = Path(directory) / "compat.py"; source.write_text(SOURCE, encoding="utf-8")
            args = ["--require-source", "--source", str(source), "--expected-commit", "a" * 40]
            for outputs in (["b" * 40], ["a" * 40, " M compat.py"]):
                with patch.object(guard.subprocess, "check_output", side_effect=outputs), self.assertRaises(ValueError):
                    guard.main(args)

    def test_missing_or_invalid_snapshot_fails(self):
        with TemporaryDirectory() as directory:
            path = Path(directory) / "snapshot.json"
            with self.assertRaises(FileNotFoundError): guard.snapshot_floors(path)
            path.write_text(json.dumps({"schema": 1, "registry_sha256": "wrong"}), encoding="utf-8")
            with self.assertRaises(ValueError): guard.snapshot_floors(path)


if __name__ == "__main__":
    unittest.main()
