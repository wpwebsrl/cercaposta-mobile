"""Run the real Gradle compatibility loader on disposable source trees using JDK 17."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


class AndroidCompatibility(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = Path(__file__).resolve().parents[1]
        gradle_user = Path(os.environ.get("GRADLE_USER_HOME", str(Path.home() / ".gradle")))
        properties = (cls.root / "android/gradle/wrapper/gradle-wrapper.properties").read_text()
        version = re.search(r"gradle-([\d.]+)-all\.zip", properties).group(1)
        libraries = list((gradle_user / f"wrapper/dists/gradle-{version}-all").glob(f"*/gradle-{version}/lib"))
        if not libraries:
            raise RuntimeError("Run the project Gradle wrapper before these integration tests")
        cls.classpath = str(libraries[0] / "*")
        cls.java = str(Path(os.environ["JAVA_HOME"]) / "bin" / ("java.exe" if os.name == "nt" else "java"))

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="cercaposta-native-compat-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        for directory in ("android", "tool", "flutter/packages/flutter_tools/gradle", "plugin/android"):
            (self.root / directory).mkdir(parents=True)
        (self.root / "flutter/LICENSE").write_text("Synthetic test licence\n")
        (self.root / "plugin/LICENSE").write_text("Synthetic test licence\n")
        for name in ("flutter/packages/flutter_tools/gradle/source.kt", "plugin/android/source.kt"):
            (self.root / name).write_text("old API\n", encoding="utf-8")
        (self.root / ".flutter-plugins-dependencies").write_text(json.dumps({
            "version": "3.32.3", "plugins": {"android": [{"name": "sample", "path": str(self.root / "plugin")}]} }), encoding="utf-8")
        sha = lambda text: hashlib.sha256(text.encode()).hexdigest()
        self.manifest = {"format": 1, "jdk_major": 17, "flutter_version": "3.32.3", "components": [
            {"name": name, "files": [{"path": "source.kt", "before_sha256": sha("old API\n"),
                                       "after_sha256": sha("modern API\n"),
                                       "replacements": [{"before": "old API", "after": "modern API", "count": 1}]}]}
            for name in ("$flutter", "sample")]}
        loader = Path(__file__).with_name("android_compat.gradle").resolve().as_posix()
        self.runner = self.root / "verify.groovy"
        self.runner.write_text("""
def root = new File(args[0])
def values = [cercapostaOriginalFlutterSdk: new File(root, 'flutter').path]
def extras = new Expando(get: { String key -> values[key] }, set: { String key, Object value -> values[key] = value })
def descriptor = new Expando(projectDir: new File(root, 'plugin/android'))
def configuration = new Expando(settingsDir: new File(root, 'android'), ext: extras)
configuration.findProject = { String name -> name == ':sample' ? descriptor : null }
def callbacks = []
def lifecycle = new Expando(settingsEvaluated: { Closure callback -> callbacks.add(callback) })
def shell = new GroovyShell(new Binding([settings: configuration, gradle: lifecycle]))
shell.evaluate(new File('LOADER'))
callbacks.each { it.call(configuration) }
assert descriptor.projectDir != new File(root, 'plugin/android')
assert new File(descriptor.projectDir, 'source.kt').text == 'modern API\\n'
assert new File(descriptor.projectDir.parentFile, 'LICENSE').exists()
assert new File(values.cercapostaFlutterGradle, 'source.kt').text == 'modern API\\n'
println('FIXTURE VERIFIED')
""".replace("LOADER", loader), encoding="utf-8")

    def invoke(self):
        (self.root / "tool/android_compat_patches.json").write_text(json.dumps(self.manifest), encoding="utf-8")
        return subprocess.run([self.java, "-Dfile.encoding=UTF-8", "-cp", self.classpath,
                               "groovy.ui.GroovyMain", str(self.runner), str(self.root)],
                              capture_output=True, text=True, encoding="utf-8", timeout=90)

    def test_real_loader_stages_sources_and_licences_without_modifying_originals(self):
        for _ in range(2):
            result = self.invoke()
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("FIXTURE VERIFIED", result.stdout)
            self.assertEqual((self.root / "plugin/android/source.kt").read_text(), "old API\n")
            self.assertEqual((self.root / "flutter/packages/flutter_tools/gradle/source.kt").read_text(), "old API\n")

    def test_upstream_source_change_fails_before_staging(self):
        (self.root / "plugin/android/source.kt").write_text("unexpected update\n")
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("source changed", result.stderr)
        self.assertFalse((self.root / ".dart_tool").exists())

    def test_wrong_replacement_count_fails(self):
        self.manifest["components"][0]["files"][0]["replacements"][0]["count"] = 2
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("context changed", result.stderr)

    def test_wrong_result_hash_fails(self):
        self.manifest["components"][0]["files"][0]["after_sha256"] = "0" * 64
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("result mismatch", result.stderr)

    def test_path_escape_fails(self):
        self.manifest["components"][1]["files"][0]["path"] = "../LICENSE"
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("path escapes", result.stderr)

    def test_flutter_change_requires_review(self):
        self.manifest["flutter_version"] = "0.0.0"
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Review Android compatibility patches", result.stderr)


if __name__ == "__main__":
    unittest.main()
