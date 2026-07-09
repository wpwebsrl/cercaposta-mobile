#!/usr/bin/env python3
"""Fail if the app's pubspec version is below the server's supported floor.

The floor lives in the server's compatibility registry (backend/app/core/compat.py),
which is a SEPARATE private repository: in CI (where only this repo is checked out)
the guard skips with a notice, and the floor must be verified before each release.
Locally the registry is found automatically when the server repo is checked out as
a sibling directory (../cercaposta or ../backend layout), or point to it explicitly:

    CERCAPOSTA_COMPAT=/path/to/backend/app/core/compat.py python tool/check_version_floor.py
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

MOBILE = Path(__file__).resolve().parents[1]
_REL = Path("backend") / "app" / "core" / "compat.py"
_CANDIDATES = [
    Path(p) for p in ([os.environ["CERCAPOSTA_COMPAT"]] if os.environ.get("CERCAPOSTA_COMPAT") else [])
] + [
    MOBILE.parent / _REL,                 # historical monorepo layout (mobile/ inside the server repo)
    MOBILE.parent / "cercaposta" / _REL,  # sibling checkout: D:\sviluppo\{cercaposta,cercaposta-mobile}
]
COMPAT = next((p for p in _CANDIDATES if p.exists()), _CANDIDATES[-1])


def parse_semver(value: str) -> tuple[int, int, int]:
    parts: list[int] = []
    for chunk in value.split(".")[:3]:
        digits = ""
        for char in chunk:
            if char.isdigit():
                digits += char
            else:
                break
        parts.append(int(digits) if digits else 0)
    parts += [0] * (3 - len(parts))
    return parts[0], parts[1], parts[2]


def pubspec_version() -> str:
    text = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")
    match = re.search(r"^version:\s*([0-9.]+)", text, re.MULTILINE)
    if not match:
        raise SystemExit("could not read 'version:' from pubspec.yaml")
    return match.group(1)


def floor_for(source: str, client: str) -> str:
    match = re.search(rf'"{client}"\s*:\s*\((?P<body>.*?)\),\s*(?:\n|}})', source, re.DOTALL)
    if not match:
        raise SystemExit(f"no '{client}' entry in compat.py BREAKING_CHANGES")
    versions = re.findall(r'"(\d+\.\d+\.\d+)"', match.group("body"))
    return max(versions, key=parse_semver) if versions else "0.0.0"


def main() -> int:
    if not COMPAT.exists():
        print("compat.py not found — skipping floor guard (server repo not available; "
              "verify the floor manually before releasing)")
        return 0
    source = COMPAT.read_text(encoding="utf-8")
    current = pubspec_version()
    floors = {c: floor_for(source, c) for c in ("ios", "android")}
    failed = False
    for client, floor in floors.items():
        if parse_semver(current) < parse_semver(floor):
            print(f"FAIL: pubspec {current} < {client} floor {floor}")
            failed = True
        else:
            print(f"ok: pubspec {current} >= {client} floor {floor}")
    if failed:
        print("Bump 'version:' in pubspec.yaml before shipping.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
