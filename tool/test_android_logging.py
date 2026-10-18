"""Exercise the shared logging options against real Gradle, including a failure."""
import os
from pathlib import Path
import tempfile
import unittest

from build_android import ROOT, native_logging_options, step
from flutter_jdk17 import environment


class NativeDiagnosticVisibility(unittest.TestCase):
    def test_real_gradle_preserves_warnings_errors_and_rejects_failure(self):
        java = Path(os.environ["JAVA_HOME"])
        wrapper = ROOT / "android" / ("gradlew.bat" if os.name == "nt" else "gradlew")
        with tempfile.TemporaryDirectory(prefix="cercaposta-gradle-logging-") as directory:
            root = Path(directory)
            (root / "settings.gradle").write_text("rootProject.name = 'diagnostic-visibility'\n")
            # A user's quiet setting must not defeat the explicit build options.
            (root / "gradle.properties").write_text("org.gradle.logging.level=quiet\n")
            (root / "build.gradle").write_text("""
assert JavaVersion.current().majorVersion == '17'
tasks.register('visibility') {
    doLast {
        logger.info('LOGGING_FIXTURE_INFO')
        logger.warn('LOGGING_FIXTURE_WARNING')
        logger.error('LOGGING_FIXTURE_ERROR')
    }
}
tasks.register('expectedFailure') {
    doLast {
        logger.warn('LOGGING_FIXTURE_WARNING')
        throw new GradleException('LOGGING_FIXTURE_FAILURE')
    }
}
""", encoding="utf-8")
            with environment(java, Path(os.environ.get("ANDROID_HOME", directory))) as env:
                for name, task, info in (("lifecycle", "visibility", False),
                                         ("info", "visibility", True),
                                         ("failure", "expectedFailure", False)):
                    with self.subTest(case=name):
                        log = root / (name + ".log")
                        command = [str(wrapper), "-p", str(root), task, "--offline",
                                   *native_logging_options(info)]
                        if name == "failure":
                            with self.assertRaisesRegex(RuntimeError, "exit code"):
                                step(command, root, env, log, "BUILD SUCCESSFUL")
                        else:
                            step(command, root, env, log, "BUILD SUCCESSFUL")
                        text = log.read_text(encoding="utf-8")
                        self.assertIn("LOGGING_FIXTURE_WARNING", text)
                        self.assertIn("LOGGING_FIXTURE_FAILURE" if name == "failure" else "LOGGING_FIXTURE_ERROR", text)
                        self.assertEqual("LOGGING_FIXTURE_INFO" in text, info)


if __name__ == "__main__":
    unittest.main()
