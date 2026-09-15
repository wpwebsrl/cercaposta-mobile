"""Reject mutable actions or a stale action lock before mobile release checks."""
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
recorded = json.loads((ROOT / ".github/actions-lock.json").read_text(encoding="utf-8"))
expected = {(key.rsplit("@", 1)[0], value) for key, value in recorded.items()}
observed = set()
for path in (ROOT / ".github/workflows").glob("*.yml"):
    for match in re.finditer(r"uses:\s+([^\s#]+)", path.read_text(encoding="utf-8")):
        value = match[1]
        if value.startswith("./"):
            continue
        if not re.fullmatch(r"[\w./-]+@[a-f0-9]{40}", value):
            raise SystemExit("Unpinned action: " + path.name)
        observed.add(tuple(value.rsplit("@", 1)))
if observed != expected:
    raise SystemExit("Workflow revisions and actions-lock.json differ")
print("All mobile actions match the immutable lock")
