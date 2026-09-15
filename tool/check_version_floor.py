#!/usr/bin/env python3
"""Verify both authentication and feature floors; missing release sources are an error."""
from __future__ import annotations

import argparse
import ast
import hashlib
import json
import os
import re
import subprocess
from pathlib import Path

MOBILE = Path(__file__).resolve().parents[1]
SNAPSHOT = MOBILE / "tool/client-compatibility.json"


def parse_semver(value: str) -> tuple[int, int, int]:
    match = re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:\+[0-9A-Za-z.-]+)?", value)
    if not match:
        raise ValueError("Invalid stable version")
    return tuple(map(int, match.groups()))


def floor_for(source: str, client: str) -> str:
    registries = {}
    for node in ast.parse(source).body:
        if isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name):
            if node.target.id in {"AUTH_BREAKING", "FEATURE_BREAKING"}:
                registries[node.target.id] = ast.literal_eval(node.value)
    if set(registries) != {"AUTH_BREAKING", "FEATURE_BREAKING"}:
        raise ValueError("Both server registries are required")
    versions = [version for rows in registries.values() for version, _ in rows[client]]
    return max(versions, key=parse_semver)


def snapshot_floors(path: Path) -> dict[str, str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema") != 1 or not re.fullmatch(r"[a-f0-9]{64}", data.get("registry_sha256", "")):
        raise ValueError("Invalid compatibility snapshot")
    return {client: max((data["clients"][client]["auth"], data["clients"][client]["feature"]), key=parse_semver)
            for client in ("ios", "android")}


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=os.environ.get("CERCAPOSTA_COMPAT"))
    parser.add_argument("--expected-commit", default="")
    parser.add_argument("--require-source", action="store_true")
    args = parser.parse_args(argv)
    version_match = re.search(r"^version:\s*(\S+)", (MOBILE / "pubspec.yaml").read_text(encoding="utf-8"), re.MULTILINE)
    if not version_match:
        raise ValueError("pubspec version missing")
    current = version_match.group(1)
    parse_semver(current)
    if args.require_source and (not args.source or not re.fullmatch(r"[a-f0-9]{40}", args.expected_commit)):
        raise ValueError("Release requires the server registry checked out at an approved full commit SHA")
    if args.source:
        if args.expected_commit:
            head = subprocess.check_output(["git", "-C", str(args.source.parent), "rev-parse", "HEAD"], text=True).strip()
            if head != args.expected_commit:
                raise ValueError("Server checkout does not match approved commit")
            dirty = subprocess.check_output(["git", "-C", str(args.source.parent), "status", "--porcelain", "--", args.source.name], text=True)
            if dirty.strip():
                raise ValueError("Server registry has uncommitted changes")
        source = args.source.read_text(encoding="utf-8")
        floors = {client: floor_for(source, client) for client in ("ios", "android")}
        print("Server registry SHA-256:", hashlib.sha256(source.encode("utf-8")).hexdigest())
        print("Verified server revision:", args.expected_commit or "local source")
    else:
        floors = snapshot_floors(SNAPSHOT)
        print("Checking versioned public snapshot (release separately requires the approved server checkout)")
    for client, floor in floors.items():
        if parse_semver(current) < parse_semver(floor):
            raise ValueError(f"pubspec {current} < {client} floor {floor}")
        print(f"ok: pubspec {current} >= {client} auth/feature floor {floor}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, KeyError, OSError, SyntaxError, subprocess.CalledProcessError) as error:
        raise SystemExit(f"Compatibility check failed: {error}") from None
