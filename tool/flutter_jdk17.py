"""Run Flutter with an isolated JDK-17 configuration, without changing user settings."""
import argparse
from contextlib import contextmanager
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile


def require_jdk17(java_home: Path) -> None:
    java = java_home / "bin" / ("java.exe" if os.name == "nt" else "java")
    version = subprocess.run([str(java), "--version"], capture_output=True, text=True,
                             encoding="utf-8", check=True).stdout
    if not re.search(r"(?:openjdk|java) 17(?:[.\s])", version):
        raise ValueError("A full JDK 17 is required")


@contextmanager
def environment(java_home: Path, android_sdk: Path):
    """Share one disposable JDK/SDK selection across Flutter and native Gradle."""
    require_jdk17(java_home)
    env = dict(os.environ)
    env.update(JAVA_HOME=str(java_home.resolve()), ANDROID_HOME=str(android_sdk.resolve()),
               ANDROID_SDK_ROOT=str(android_sdk.resolve()), FLUTTER_SUPPRESS_ANALYTICS="true")
    env["PATH"] = str(java_home.resolve() / "bin") + os.pathsep + env.get("PATH", "")
    env["GRADLE_OPTS"] = env.get("GRADLE_OPTS", "") + f' -Dorg.gradle.java.home="{java_home.resolve().as_posix()}"'
    # Flutter prefers Android Studio's bundled Java over JAVA_HOME unless jdk-dir
    # is explicit. Keep that choice in this process's disposable configuration.
    with tempfile.TemporaryDirectory(prefix="cercaposta-flutter-jdk17-") as directory:
        if os.name == "nt":
            env["APPDATA"] = directory
            configuration = Path(directory) / ".flutter_settings"
        else:
            if (Path.home() / ".flutter_settings").exists():
                raise ValueError("A legacy Flutter home configuration takes precedence; use an isolated build account")
            env["XDG_CONFIG_HOME"] = directory
            configuration = Path(directory) / "settings"
        configuration.write_text(json.dumps({"jdk-dir": str(java_home.resolve()),
                                             "android-sdk": str(android_sdk.resolve())}), encoding="utf-8")
        yield env


def command(flutter_sdk: Path, arguments: list[str]) -> list[str]:
    dart = flutter_sdk / "bin/cache/dart-sdk/bin" / ("dart.exe" if os.name == "nt" else "dart")
    snapshot = flutter_sdk / "bin/cache/flutter_tools.snapshot"
    return [str(dart), str(snapshot), "--suppress-analytics", *arguments]


def run(java_home: Path, flutter_sdk: Path, android_sdk: Path, arguments: list[str]) -> int:
    with environment(java_home, android_sdk) as env:
        return subprocess.run(command(flutter_sdk, arguments), env=env).returncode


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--java-home", type=Path, required=True)
    parser.add_argument("--flutter-sdk", type=Path, required=True)
    parser.add_argument("--android-sdk", type=Path, required=True)
    parser.add_argument("arguments", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    arguments = args.arguments[1:] if args.arguments[:1] == ["--"] else args.arguments
    if not arguments:
        parser.error("A Flutter command is required after --")
    return run(args.java_home, args.flutter_sdk, args.android_sdk, arguments)


if __name__ == "__main__":
    raise SystemExit(main())
