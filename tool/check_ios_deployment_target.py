#!/usr/bin/env python3
"""Fail CI if the iOS deployment target falls below the App Store floor."""

from __future__ import annotations

import plistlib
import re
import sys
from pathlib import Path


REQUIRED_TARGET = (15, 0)
ROOT = Path(__file__).resolve().parents[1]
FRAMEWORK_PLIST = ROOT / "ios" / "Flutter" / "AppFrameworkInfo.plist"
XCODE_PROJECT = ROOT / "ios" / "Runner.xcodeproj" / "project.pbxproj"


def parse_version(value: str) -> tuple[int, ...]:
    try:
        return tuple(int(part) for part in value.split("."))
    except ValueError as exc:
        raise ValueError(f"versione iOS non valida: {value!r}") from exc


def fail(message: str) -> None:
    print(f"ERRORE: {message}", file=sys.stderr)
    raise SystemExit(1)


with FRAMEWORK_PLIST.open("rb") as stream:
    framework_info = plistlib.load(stream)

framework_target = str(framework_info.get("MinimumOSVersion", ""))
try:
    if parse_version(framework_target) < REQUIRED_TARGET:
        fail(
            "MinimumOSVersion in AppFrameworkInfo.plist deve essere almeno 15.0 "
            f"(trovato {framework_target or 'mancante'})"
        )
except ValueError as exc:
    fail(str(exc))

project_text = XCODE_PROJECT.read_text(encoding="utf-8")
project_targets = re.findall(
    r"IPHONEOS_DEPLOYMENT_TARGET\s*=\s*([0-9.]+);", project_text
)
if not project_targets:
    fail("nessun IPHONEOS_DEPLOYMENT_TARGET trovato nel progetto Xcode")

for target in project_targets:
    try:
        if parse_version(target) < REQUIRED_TARGET:
            fail(
                "tutte le configurazioni Xcode devono richiedere almeno iOS 15.0 "
                f"(trovato {target})"
            )
    except ValueError as exc:
        fail(str(exc))

print(
    "Deployment target iOS valido: "
    f"framework={framework_target}; Xcode={', '.join(project_targets)}"
)
