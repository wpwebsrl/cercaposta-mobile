"""Protect the process-local JDK selection from Android Studio/global config overrides."""
import json
import os
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

from flutter_jdk17 import run


class FlutterJdk17(unittest.TestCase):
    def test_private_configuration_and_exact_arguments(self):
        original = dict(os.environ)
        seen = []

        def execute(arguments, **kwargs):
            if arguments[-1] == "--version":
                return subprocess.CompletedProcess(arguments, 0, "openjdk 17.0.20.1 LTS\n")
            env = kwargs["env"]
            configuration = Path(env["APPDATA"]) / ".flutter_settings" if os.name == "nt" else Path(env["XDG_CONFIG_HOME"]) / "settings"
            settings = json.loads(configuration.read_text())
            self.assertEqual(settings["jdk-dir"], str(Path("jdk17").resolve()))
            self.assertEqual(env["JAVA_HOME"], settings["jdk-dir"])
            self.assertIn(f'-Dorg.gradle.java.home="{Path("jdk17").resolve().as_posix()}"', env["GRADLE_OPTS"])
            self.assertEqual(arguments[-3:], ["build", "apk", "--debug"])
            self.assertIn("--suppress-analytics", arguments)
            # Unlike the CLI flag alone, this reaches nested Gradle Flutter
            # processes and avoids repeated first-run consent banners.
            self.assertEqual(env["FLUTTER_SUPPRESS_ANALYTICS"], "true")
            seen.append(configuration)
            return subprocess.CompletedProcess(arguments, 7)

        with patch("flutter_jdk17.subprocess.run", side_effect=execute), patch("pathlib.Path.exists", return_value=False):
            self.assertEqual(run(Path("jdk17"), Path("flutter"), Path("sdk"), ["build", "apk", "--debug"]), 7)
        self.assertEqual(dict(os.environ), original)
        self.assertEqual(len(seen), 1)
        self.assertFalse(seen[0].exists())

    def test_other_jdk_is_rejected_before_flutter(self):
        result = subprocess.CompletedProcess([], 0, "openjdk 24.0.1\n")
        with patch("flutter_jdk17.subprocess.run", return_value=result) as execute:
            with self.assertRaisesRegex(ValueError, "JDK 17"):
                run(Path("jdk24"), Path("flutter"), Path("sdk"), ["build", "apk"])
            self.assertEqual(execute.call_count, 1)


if __name__ == "__main__":
    unittest.main()
