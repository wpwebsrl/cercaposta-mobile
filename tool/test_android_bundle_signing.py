"""Real JDK signature verification with disposable synthetic upload/debug keys."""
import hashlib
import os
import shutil
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path

from verify_android_artifact import verify


class BundleSigningTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="cercaposta-signing-test-")
        cls.root = Path(cls.temp.name)
        cls.tools = Path(os.environ["JAVA_HOME"]) / "bin" if "JAVA_HOME" in os.environ else None
        cls.source = Path(__file__).with_name("VerifyAndroidBundle.java")
        cls.pins = {}
        for alias, subject in [("upload", "CN=CercaPosta Synthetic Test"), ("debug", "CN=Android Debug,O=Android,C=US")]:
            cls.run_jdk("keytool", "-genkeypair", "-alias", alias, "-keyalg", "RSA", "-keysize", "2048",
                        "-validity", "30", "-dname", subject, "-keystore", str(cls.root / f"{alias}.p12"),
                        "-storetype", "PKCS12", "-storepass", "synthetic-test-only", "-keypass", "synthetic-test-only")
            cert = cls.root / f"{alias}.der"
            cls.run_jdk("keytool", "-exportcert", "-alias", alias, "-keystore", str(cls.root / f"{alias}.p12"),
                        "-storepass", "synthetic-test-only", "-file", str(cert))
            cls.pins[alias] = hashlib.sha256(cert.read_bytes()).hexdigest()
        cls.original = cls.root / "signed.aab"
        cls.make_bundle(cls.original)
        cls.sign(cls.original, "upload")

    @classmethod
    def run_jdk(cls, tool, *args, check=True):
        executable = str(cls.tools / (tool + (".exe" if os.name == "nt" else ""))) if cls.tools else tool
        return subprocess.run([executable, *args], capture_output=True, text=True, timeout=90, check=check)

    @classmethod
    def make_bundle(cls, path):
        with zipfile.ZipFile(path, "w") as bundle:
            bundle.writestr("base/manifest/AndroidManifest.xml", b"synthetic manifest")
            bundle.writestr("base/dex/classes.dex", b"synthetic dex")
            bundle.writestr("META-INF/services/example", b"also must be signed")

    @classmethod
    def sign(cls, path, alias):
        cls.run_jdk("jarsigner", "-keystore", str(cls.root / f"{alias}.p12"), "-storepass", "synthetic-test-only",
                    "-digestalg", "SHA-256", "-sigalg", "SHA256withRSA", str(path), alias)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def verify(self, path, pin):
        return self.run_jdk("java", str(self.source), str(path), pin, check=False).returncode

    def test_approved_signed_payload(self):
        self.assertEqual(self.verify(self.original, self.pins["upload"]), 0)
        verify(self.original, self.pins["upload"])

    def test_wrong_or_missing_certificate_pin(self):
        for pin in ["", "x", "0" * 64, self.pins["debug"]]:
            with self.subTest(pin=pin):
                self.assertNotEqual(self.verify(self.original, pin), 0)

    def test_unsigned_bundle(self):
        path = self.root / "unsigned.aab"
        self.make_bundle(path)
        self.assertNotEqual(self.verify(path, self.pins["upload"]), 0)

    def test_debug_certificate_rejected_even_when_pin_matches(self):
        path = self.root / "debug.aab"
        self.make_bundle(path)
        self.sign(path, "debug")
        self.assertNotEqual(self.verify(path, self.pins["debug"]), 0)

    def test_tampered_signed_content(self):
        path = self.root / "tampered.aab"
        with zipfile.ZipFile(self.original) as source, zipfile.ZipFile(path, "w") as target:
            for entry in source.infolist():
                target.writestr(entry, b"changed" if entry.filename.endswith("classes.dex") else source.read(entry))
        self.assertNotEqual(self.verify(path, self.pins["upload"]), 0)

    def test_added_unsigned_payload_including_meta_inf_services(self):
        for name in ["base/assets/added", "META-INF/services/added"]:
            path = self.root / "injected.aab"
            shutil.copyfile(self.original, path)
            with zipfile.ZipFile(path, "a") as bundle:
                bundle.writestr(name, b"unsigned")
            self.assertNotEqual(self.verify(path, self.pins["upload"]), 0)

    def test_duplicate_or_unsafe_zip_entries(self):
        for name in ["../outside", "/absolute", "base/./ambiguous"]:
            with self.subTest(name=name):
                path = self.root / "path.aab"
                self.make_bundle(path)
                with zipfile.ZipFile(path, "a") as bundle:
                    bundle.writestr(name, b"signed but unsafe")
                self.sign(path, "upload")
                self.assertNotEqual(self.verify(path, self.pins["upload"]), 0)
        path = self.root / "duplicate.aab"
        shutil.copyfile(self.original, path)
        import warnings
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            with zipfile.ZipFile(path, "a") as bundle:
                bundle.writestr("base/dex/classes.dex", b"synthetic dex")
        self.assertNotEqual(self.verify(path, self.pins["upload"]), 0)

    def test_wrapper_rejects_missing_pin_or_unsupported_artifact(self):
        with self.assertRaises(ValueError):
            verify(self.original, "")
        with self.assertRaises(ValueError):
            verify(self.root / "not-an-app.zip", self.pins["upload"])


if __name__ == "__main__":
    unittest.main()
