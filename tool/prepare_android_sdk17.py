"""Prepare an isolated SDK profile for AGP 8.13/JDK 17 using Google's SDK manager."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import tempfile
import urllib.request
import xml.etree.ElementTree as ET
import zipfile

from flutter_jdk17 import require_jdk17


def content_hashes(directory: Path) -> dict[str, str]:
    return {p.relative_to(directory).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in directory.rglob("*") if p.is_file() and p.name != "package.xml" and ".installer" not in p.parts}


def validate_metadata_schema(metadata: Path) -> None:
    maximum = {"repository2": 3, "addon2": 3, "sys-img2": 4}
    for _, (_, namespace) in ET.iterparse(metadata, events=["start-ns"]):
        match = re.fullmatch(r"http://schemas.android.com/sdk/android/repo/(repository2|addon2|sys-img2)/(\d+)", namespace)
        if match and int(match[2]) > maximum[match[1]]:
            raise ValueError("SDK profile metadata schema changed; prepare a new isolated profile with tools 19: " + str(metadata))


def validate_metadata(target: Path) -> int:
    checked = 0
    relatives = ["platforms/android-34", "platforms/android-35", "platforms/android-36",
                 "platform-tools", "build-tools/35.0.0", "ndk/27.0.12077973"]
    relatives.extend(p.relative_to(target).as_posix() for p in (target / "cmdline-tools").glob("*")
                     if (p / "source.properties").is_file())
    for relative in relatives:
        metadata = target / relative / "package.xml"
        if not metadata.is_file():
            if relative == "platforms/android-36" or relative.startswith("cmdline-tools/"):
                raise ValueError("The official manager did not register the Android platform metadata")
            continue
        validate_metadata_schema(metadata)
        checked += 1
    return checked


def register_command_line_tools(target: Path, env: dict[str, str]) -> int:
    """Copy authentic installer metadata only after verifying every installed byte."""
    missing = []
    for directory in sorted((target / "cmdline-tools").iterdir()):
        if not (directory / "source.properties").is_file() or (directory / "package.xml").is_file():
            continue
        if not directory.resolve().is_relative_to(target.resolve()):
            raise ValueError("Command-line tools must remain inside the isolated SDK")
        version = directory.name
        if version not in ("19.0", "23.0"):
            raise ValueError("Review unregistered command-line tools version: " + version)
        properties = (directory / "source.properties").read_text(encoding="utf-8")
        if not re.search(r"(?m)^Pkg\.Revision\s*=\s*" + re.escape(version) + r"[ \t]*$", properties):
            raise ValueError("Command-line tools directory/revision mismatch: " + version)
        missing.append(directory)
    if not missing:
        return 0
    # An SDK archive has no package.xml. Do not invent one or rewrite namespaces.
    # Obtain it from a real Google SDK-manager installation outside the build SDK.
    # Existing tools/platforms/global SDK are never replaced or moved.
    with tempfile.TemporaryDirectory(prefix="cercaposta-sdk-registration-") as folder:
        installed = Path(folder)
        shutil.copytree(target / "licenses", installed / "licenses")
        command = target / "cmdline-tools/19.0/bin" / ("sdkmanager.bat" if os.name == "nt" else "sdkmanager")
        isolated_env = dict(env, ANDROID_HOME=str(installed), ANDROID_SDK_ROOT=str(installed))
        subprocess.run([str(command), "--sdk_root=" + str(installed),
                        *("cmdline-tools;" + p.name for p in missing)],
                       env=isolated_env, stdin=subprocess.DEVNULL, check=True, timeout=1200)
        # Validate all packages before copying any metadata into the build SDK.
        pending = []
        for directory in missing:
            official = installed / "cmdline-tools" / directory.name
            metadata = official / "package.xml"
            validate_metadata_schema(metadata)
            package = ET.parse(metadata).getroot().find("localPackage")
            if package is None or package.get("path") != "cmdline-tools;" + directory.name:
                raise ValueError("Official command-line tools metadata identity mismatch")
            revision = package.find("revision")
            if (revision is None or revision.findtext("major") != directory.name.split(".")[0]
                    or revision.findtext("minor", "0") != "0" or revision.findtext("micro", "0") != "0"):
                raise ValueError("Official command-line tools metadata revision mismatch")
            if content_hashes(directory) != content_hashes(official):
                raise ValueError("Official command-line tools differ from the build SDK: " + directory.name)
            pending.append((metadata, directory / "package.xml"))
        for source, destination in pending:
            shutil.copyfile(source, destination)
    return len(missing)


def tools19(source: Path, target: Path) -> None:
    original = source / "cmdline-tools/19.0"
    if target.exists():
        return
    if original.is_dir():
        shutil.copytree(original, target)
        return
    # Exact stable release, official repository metadata and its archive checksum.
    with urllib.request.urlopen("https://dl.google.com/android/repository/repository2-3.xml", timeout=60) as response:
        metadata = ET.fromstring(response.read())
    package = next(p for p in metadata.findall("remotePackage") if p.get("path") == "cmdline-tools;19.0")
    host = {"Windows": "windows", "Linux": "linux", "Darwin": "macosx"}[platform.system()]
    archive = next(a for a in package.findall("archives/archive") if a.findtext("host-os") == host)
    url = archive.findtext("complete/url")
    if not url or "/" in url or "\\" in url:
        raise ValueError("Invalid Google SDK archive name")
    with tempfile.TemporaryDirectory(prefix="cercaposta-sdk19-") as folder:
        download = Path(folder) / "tools.zip"
        urllib.request.urlretrieve("https://dl.google.com/android/repository/" + url, download)
        if hashlib.sha1(download.read_bytes()).hexdigest() != archive.findtext("complete/checksum"):
            raise ValueError("Google SDK archive checksum mismatch")
        with zipfile.ZipFile(download) as bundle:
            if any(not (Path(folder) / name).resolve().is_relative_to(Path(folder).resolve()) for name in bundle.namelist()):
                raise ValueError("SDK archive path escapes its destination")
            bundle.extractall(folder)
        shutil.copytree(Path(folder) / "cmdline-tools", target)


def prepare(source: Path, target: Path, java: Path) -> dict:
    require_jdk17(java)
    source, target = source.resolve(), target.resolve()
    if source == target or target.is_relative_to(source) or source.is_relative_to(target):
        raise ValueError("The build SDK must be separate from the original SDK")
    marker = target / "cercaposta-build-sdk.json"
    if target.exists() and any(target.iterdir()) and not marker.is_file():
        raise ValueError("Refusing to modify a nonempty SDK without a CercaPosta build-profile marker")
    if marker.is_file() and Path(json.loads(marker.read_text(encoding="utf-8"))["original_sdk"]).resolve() != source:
        raise ValueError("This SDK profile belongs to another source SDK")
    target.mkdir(parents=True, exist_ok=True)
    marker.write_text(json.dumps({"format": 1, "original_sdk": str(source), "state": "preparing"}), encoding="utf-8")
    # Reuse already-accepted licence records; never accept licences automatically.
    if not (target / "licenses").exists():
        shutil.copytree(source / "licenses", target / "licenses")
    tools19(source, target / "cmdline-tools/19.0")
    if os.name != "nt":
        for executable in (target / "cmdline-tools/19.0/bin").iterdir():
            if executable.is_file():
                executable.chmod(executable.stat().st_mode | 0o100)
    packages = ["platforms;android-36", "platform-tools"]
    for relative, package in (("build-tools/35.0.0", "build-tools;35.0.0"),
                              ("platforms/android-34", "platforms;android-34"),
                              ("platforms/android-35", "platforms;android-35"),
                              ("ndk/27.0.12077973", "ndk;27.0.12077973")):
        original, staged = source / relative, target / relative
        if staged.exists():
            continue
        if original.is_dir():
            staged.parent.mkdir(parents=True, exist_ok=True)
            if relative.startswith("ndk/"):
                try:
                    staged.symlink_to(original, target_is_directory=True)
                except OSError:
                    if os.name != "nt":
                        raise
                    env = dict(os.environ, CERCAPOSTA_NDK_DEST=str(staged), CERCAPOSTA_NDK_SOURCE=str(original))
                    subprocess.run(["powershell.exe", "-NoProfile", "-Command",
                                    "New-Item -ItemType Junction -Path $env:CERCAPOSTA_NDK_DEST -Target $env:CERCAPOSTA_NDK_SOURCE | Out-Null"],
                                   env=env, check=True)
            else:
                shutil.copytree(original, staged)
        else:
            packages.append(package)
    env = dict(os.environ, JAVA_HOME=str(java.resolve()), ANDROID_HOME=str(target), ANDROID_SDK_ROOT=str(target))
    env["PATH"] = str(java.resolve() / "bin") + os.pathsep + env.get("PATH", "")
    registered_tools = register_command_line_tools(target, env)
    command = target / "cmdline-tools/19.0/bin" / ("sdkmanager.bat" if os.name == "nt" else "sdkmanager")
    if os.name != "nt":
        command.chmod(command.stat().st_mode | 0o100)
    subprocess.run([str(command), "--sdk_root=" + str(target), *packages], env=env,
                   stdin=subprocess.DEVNULL, check=True, timeout=1200)
    metadata_files = validate_metadata(target)
    # Reinstallation registers the official platform with schema v3. SDK binaries
    # and resources must remain identical when the source package already exists.
    comparisons = {}
    for relative in ("platforms/android-36", "platform-tools"):
        if (source / relative).is_dir():
            original, staged = content_hashes(source / relative), content_hashes(target / relative)
            if original != staged:
                raise ValueError("Isolated SDK package differs from the source: " + relative)
            comparisons[relative] = {"files": len(original), "identical": True}
    properties = (target / "platforms/android-36/source.properties").read_text()
    if not re.search(r"(?m)^Pkg\.Revision\s*=\s*2[ \t]*$", properties) or not re.search(r"(?m)^AndroidVersion\.ApiLevel\s*=\s*36[ \t]*$", properties):
        raise ValueError("Android platform revision changed; review this SDK profile")
    report = {"format": 1, "original_sdk": str(source), "state": "verified",
              "sdk": str(target), "comparisons": comparisons,
              "platform": "36 revision 2", "plugin_platforms": [34, 35],
              "compatible_metadata_files": metadata_files,
              "newly_registered_command_line_tools": registered_tools,
              "build_tools": "35.0.0", "ndk": "27.0.12077973"}
    marker.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-sdk", type=Path, required=True)
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument("--java-home", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(prepare(args.source_sdk, args.destination, args.java_home), indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
