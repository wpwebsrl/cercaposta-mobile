"""Exercise the real Gradle release signing gate using disposable synthetic keys."""
import hashlib
import os
import subprocess
import tempfile
from pathlib import Path


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    android = root / "android"
    java_bin = Path(os.environ["JAVA_HOME"]) / "bin"
    keytool = java_bin / ("keytool.exe" if os.name == "nt" else "keytool")
    gradle = android / ("gradlew.bat" if os.name == "nt" else "gradlew")
    with tempfile.TemporaryDirectory(prefix="cercaposta-gradle-signing-") as folder:
        temporary = Path(folder)
        keystore = temporary / "synthetic.p12"
        certificate = temporary / "synthetic.der"
        subprocess.run([str(keytool), "-genkeypair", "-alias", "upload", "-keyalg", "RSA", "-keysize", "2048",
                        "-validity", "30", "-dname", "CN=CercaPosta Gate Test", "-keystore", str(keystore),
                        "-storetype", "PKCS12", "-storepass", "synthetic-test-only", "-keypass", "synthetic-test-only"],
                       check=True, capture_output=True, timeout=90)
        subprocess.run([str(keytool), "-exportcert", "-alias", "upload", "-keystore", str(keystore),
                        "-storepass", "synthetic-test-only", "-file", str(certificate)],
                       check=True, capture_output=True, timeout=90)
        pin = hashlib.sha256(certificate.read_bytes()).hexdigest()
        cases = [
            ("missing properties", False, "upload", pin, False),
            ("missing fingerprint", True, "upload", "", False),
            ("wrong fingerprint", True, "upload", "0" * 64, False),
            ("debug alias", True, "androiddebugkey", pin, False),
            ("missing alias", True, "other", pin, False),
            ("approved key", True, "upload", pin, True),
        ]
        for label, exists, alias, fingerprint, should_pass in cases:
            properties = temporary / (label.replace(" ", "-") + ".properties")
            if exists:
                properties.write_text(f"storeFile={keystore.as_posix()}\nstorePassword=synthetic-test-only\n"
                                      f"keyPassword=synthetic-test-only\nkeyAlias={alias}\ncertificateSha256={fingerprint}\n",
                                      encoding="utf-8")
            environment = {key: value for key, value in os.environ.items()
                           if key.upper() != "ANDROID_UPLOAD_CERT_SHA256"}
            task = ":app:assembleRelease" if label == "missing properties" else ":app:verifyReleaseSigning"
            result = subprocess.run([str(gradle), task, "--console=plain",
                                     f"-Pcercaposta.signingProperties={properties.as_posix()}"],
                                    cwd=android, env=environment, text=True, capture_output=True, timeout=300)
            if (result.returncode == 0) != should_pass or ":app:verifyReleaseSigning" not in result.stdout:
                raise RuntimeError(f"Signing gate case failed: {label}\n{result.stdout[-2500:]}\n{result.stderr[-1500:]}")
            print(f"Passed release signing gate: {label}", flush=True)


if __name__ == "__main__":
    main()
