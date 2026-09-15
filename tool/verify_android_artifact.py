"""Verify the published Android artifact against the configured upload certificate."""
import argparse
import os
import re
import subprocess
from pathlib import Path


def verify(path: Path, expected: str, sdk: Path | None = None) -> None:
    fingerprint = expected.replace(":", "").strip().lower()
    if not re.fullmatch(r"[a-f0-9]{64}", fingerprint):
        raise ValueError("An approved upload certificate SHA-256 is required")
    java = Path(os.environ["JAVA_HOME"]) / "bin" / ("java.exe" if os.name == "nt" else "java") if "JAVA_HOME" in os.environ else "java"
    if path.suffix.lower() == ".aab":
        args = [str(java), str(Path(__file__).with_name("VerifyAndroidBundle.java")), str(path), fingerprint]
    elif path.suffix.lower() == ".apk":
        sdk = sdk or Path(os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT") or "")
        signers = sorted((sdk / "build-tools").glob("*/lib/apksigner.jar"),
                         key=lambda p: tuple(int(n) for n in re.findall(r"\d+", p.parent.parent.name)))
        if not signers:
            raise ValueError("Android SDK apksigner is required to verify an APK")
        args = [str(java), "-jar", str(signers[-1]), "verify", "--verbose", "--print-certs", str(path)]
    else:
        raise ValueError("Only APK and AAB artifacts are accepted")
    result = subprocess.run(args, capture_output=True, text=True, timeout=300)
    if result.returncode:
        raise ValueError("Android artifact signature verification failed")
    if path.suffix.lower() == ".apk":
        fingerprints = re.findall(r"^Signer #\d+ certificate SHA-256 digest: ([a-fA-F0-9]+)$", result.stdout, re.MULTILINE)
        if len(fingerprints) != 1 or fingerprints[0].lower() != fingerprint:
            raise ValueError("Unexpected or ambiguous APK signing certificate")
        if "cn=android debug" in result.stdout.lower():
            raise ValueError("Debug certificates cannot sign a release")
    print(f"Verified {path.name}; upload certificate SHA-256 {fingerprint}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--sha256", default=os.environ.get("ANDROID_UPLOAD_CERT_SHA256", ""))
    parser.add_argument("--sdk", type=Path)
    args = parser.parse_args()
    try:
        verify(args.artifact, args.sha256, args.sdk)
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        parser.exit(1, f"Release verification failed: {error}\n")


if __name__ == "__main__":
    main()
