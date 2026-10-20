"""Build Android with visible native diagnostics, then Flutter's complete postcheck.

Run from the mobile repository root. Dependencies must already be resolved with
flutter pub get --enforce-lockfile and the isolated SDK prepared. This is a build
command only: it never installs, uploads or publishes an application.
"""
import argparse
import base64
from datetime import date
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

from check_android_build_log import check
from flutter_jdk17 import command, environment
from prepare_android_sdk17 import validate_metadata

ROOT = Path(__file__).resolve().parents[1]
PLATFORMS = ("android-arm", "android-arm64", "android-x64")


def stream(arguments: list[str], cwd: Path, env: dict[str, str], log: Path) -> int:
    """Tee merged, unfiltered output as bytes; retain the actual child exit code."""
    with log.open("xb") as output:
        with subprocess.Popen(arguments, cwd=cwd, env=env, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL) as child:
            while chunk := child.stdout.read1(65536):
                output.write(chunk)
                output.flush()
                sys.stdout.buffer.write(chunk)
                sys.stdout.buffer.flush()
            return child.wait()


def step(arguments, cwd, env, log, completion):
    result = stream(arguments, cwd, env, log)
    text = log.read_text(encoding="utf-8-sig", errors="replace")
    if result:
        raise RuntimeError(f"{log.name}: command failed with exit code {result}")
    if "BUILD FAILED" in text or not re.search(completion, text):
        raise RuntimeError(f"{log.name}: missing successful completion marker")
    problems = check(text)
    if problems:
        raise RuntimeError(f"{log.name}: diagnostic gate failed\n" + "\n".join(problems))


def framework_defines(sdk: Path) -> list[str]:
    # Flutter 3.32 adds these itself. Keep native/Flutter inputs identical and
    # fail on a tool upgrade until this adapter is reviewed against its source.
    version = json.loads((sdk / "bin/cache/flutter.version.json").read_text(encoding="utf-8"))
    if (version["frameworkVersion"], version["dartSdkVersion"], version["channel"]) != ("3.32.3", "3.8.1", "stable"):
        raise ValueError("Review the Android build adapter before changing Flutter/Dart")
    return ["FLUTTER_VERSION=" + version["frameworkVersion"],
            "FLUTTER_CHANNEL=" + version["channel"],
            "FLUTTER_GIT_URL=" + version["repositoryUrl"],
            "FLUTTER_FRAMEWORK_REVISION=" + version["frameworkRevision"][:10],
            "FLUTTER_ENGINE_REVISION=" + version["engineRevision"][:10],
            "FLUTTER_DART_VERSION=" + version["dartSdkVersion"]]


def native_logging_options(info=False) -> list[str]:
    return ["--info" if info else "-Dorg.gradle.logging.level=lifecycle",
            "--console=plain", "--warning-mode=all"]


def build_arguments(args, framework):
    platforms = args.target_platform.split(",")
    if not platforms or len(set(platforms)) != len(platforms) or any(p not in PLATFORMS for p in platforms):
        raise ValueError("Use distinct supported target platforms: " + ",".join(PLATFORMS))
    date.fromisoformat(args.app_build_date)
    if not args.app_build.strip():
        raise ValueError("An explicit APP_BUILD identity is required")
    if args.build_number is not None and args.build_number <= 0:
        raise ValueError("build-number must be positive")
    if args.variant == "debug" and args.split_debug_info is not None:
        raise ValueError("split-debug-info is reserved for the release variant")
    if args.variant == "release" and args.lint:
        raise ValueError("The mandatory CI lint gate uses the debug variant")
    release = args.variant == "release"
    defines = ["APP_BUILD=" + args.app_build, "APP_BUILD_DATE=" + args.app_build_date]
    for define in args.dart_define:
        key, separator, _ = define.partition("=")
        if not separator or not key or key.startswith("FLUTTER_") or key in {d.split("=", 1)[0] for d in defines}:
            raise ValueError("Invalid, reserved or duplicate dart-define key: " + key)
        defines.append(define)
    common = ["--" + args.variant, "--target=lib/main.dart",
              "--target-platform=" + args.target_platform,
              "--track-widget-creation", "--tree-shake-icons"]
    if args.build_number is not None:
        common.append("--build-number=" + str(args.build_number))
    if args.build_name is not None:
        common.append("--build-name=" + args.build_name)
    # Flutter normalizes the Dart entry point with the host path separator.
    native = ["-Ptarget=" + str(Path("lib/main.dart")), "-Ptarget-platform=" + args.target_platform,
              "-Pbase-application-name=android.app.Application",
              "-Ptrack-widget-creation=true", "-Ptree-shake-icons=" + str(release).lower(),
              "-Pdart-obfuscation=" + str(release).lower(),
              "-Pdart-defines=" + ",".join(base64.b64encode(d.encode()).decode() for d in defines + framework)]
    if release:
        symbols = str((args.split_debug_info or Path("build/symbols")).resolve())
        common += ["--obfuscate", "--split-debug-info=" + symbols]
        native.append("-Psplit-debug-info=" + symbols)
    common += ["--dart-define=" + define for define in defines]
    return common, native


def build(args) -> None:
    if Path.cwd().resolve() != ROOT.resolve():
        raise ValueError("Run build_android.py from the mobile repository root")
    # Validate everything before creating a fresh evidence directory or building.
    framework = framework_defines(args.flutter_sdk)
    common, properties = build_arguments(args, framework)
    validate_metadata(args.android_sdk)
    marker = json.loads((args.android_sdk / "cercaposta-build-sdk.json").read_text())
    if marker.get("state") != "verified":
        raise ValueError("Prepare and verify the isolated SDK profile first")
    if args.variant == "release" and not re.fullmatch(r"[a-fA-F0-9]{64}", os.environ.get("ANDROID_UPLOAD_CERT_SHA256", "").replace(":", "").strip()):
        raise ValueError("Release requires ANDROID_UPLOAD_CERT_SHA256; the signing gate remains mandatory")
    with environment(args.java_home, args.android_sdk) as env:
        args.log_dir.mkdir(parents=True, exist_ok=False)
        report = {"state": "running", "variant": args.variant, "app_build": args.app_build,
                  "app_build_date": args.app_build_date, "target_platform": args.target_platform,
                  "native_log_level": "INFO" if args.native_info else "LIFECYCLE",
                  "warning_mode": "all", "lint": args.lint, "published": False}
        report_file = args.log_dir / "result.json"
        report_file.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        try:
            # This supported APK preparation also writes the release registrant
            # for AAB builds. No Gradle compilation occurs in config-only mode.
            # Do not pass --no-pub: plugin regeneration is skipped in that mode.
            step(command(args.flutter_sdk, ["build", "apk", "--config-only", *common]),
                 ROOT, env, args.log_dir / "configuration.log", r"Config complete\.")
            java = args.java_home / "bin" / ("java.exe" if os.name == "nt" else "java")
            step([str(java), "-Dfile.encoding=UTF-8", str(ROOT / "tool/NormalizeAndroidSdkPaths.java"),
                  str(ROOT / "android/local.properties")], ROOT, env,
                 args.log_dir / "sdk-paths.log", r"Normalized SDK path properties:")
            wrapper = ROOT / "android" / ("gradlew.bat" if os.name == "nt" else "gradlew")
            tasks = [":app:bundleRelease" if args.variant == "release" else ":app:assembleDebug"]
            if args.lint:
                tasks.append(":app:lintDebug")
            step([str(wrapper), *tasks, *native_logging_options(args.native_info), *properties], ROOT / "android", env,
                 args.log_dir / "native.log", r"BUILD SUCCESSFUL")
            # Full supported Flutter postcheck, not just artifact existence.
            # Compilation already ran above with native warnings visible.
            kind = "appbundle" if args.variant == "release" else "apk"
            step(command(args.flutter_sdk, ["build", kind, *common]), ROOT, env,
                 args.log_dir / "flutter.log", rf"Built .+\.{ 'aab' if kind == 'appbundle' else 'apk' }\b")
            artifact = ROOT / ("build/app/outputs/bundle/release/app-release.aab" if kind == "appbundle"
                               else "build/app/outputs/flutter-apk/app-debug.apk")
            if kind == "appbundle":
                step([sys.executable, str(ROOT / "tool/verify_android_artifact.py"), str(artifact)],
                     ROOT, env, args.log_dir / "signature.log", r"Verified app-release\.aab;")
            report.update(state="passed", artifact=str(artifact), bytes=artifact.stat().st_size,
                          sha256=hashlib.sha256(artifact.read_bytes()).hexdigest())
        except Exception as error:
            report.update(state="failed", error=str(error))
            raise
        finally:
            report_file.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print("Android build, diagnostic gates and Flutter postcheck passed.", flush=True)


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--java-home", type=Path, required=True)
    result.add_argument("--flutter-sdk", type=Path, required=True)
    result.add_argument("--android-sdk", type=Path, required=True)
    result.add_argument("--variant", choices=("debug", "release"), required=True)
    result.add_argument("--app-build", required=True)
    result.add_argument("--app-build-date", required=True)
    result.add_argument("--build-number", type=int)
    result.add_argument("--build-name")
    result.add_argument("--dart-define", action="append", default=[])
    result.add_argument("--target-platform", default=",".join(PLATFORMS))
    result.add_argument("--split-debug-info", type=Path)
    result.add_argument("--lint", action="store_true")
    result.add_argument("--native-info", action="store_true", help="Keep full native INFO diagnostics for investigation")
    result.add_argument("--log-dir", type=Path, required=True, help="New directory; existing evidence is never overwritten")
    return result


if __name__ == "__main__":
    try:
        build(parser().parse_args())
    except (ValueError, RuntimeError, OSError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
