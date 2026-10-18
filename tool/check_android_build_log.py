"""Reject compiler incompatibilities, native deprecations and SDK XML diagnostics."""
from pathlib import Path
import re
import sys

PROBLEMS = re.compile(
    r"\bWARNING:\s*(?:D8|R8):"
    r"|compiled with an incompatible version of Kotlin"
    r"|incompatible classes were found in dependencies"
    r"|Kotlin Gradle plugin was loaded multiple times"
    r"|this and base files have different roots"
    r"|Release app bundle failed to strip debug symbols"
    r"|Expected to find fonts for "
    r"|Gradle task .{0,80} failed with exit code [1-9]"
    r"|SDK XML versions up to"
    r"|Setting the namespace via the package attribute"
    r"|Properties should be assigned using the 'propName = value' syntax"
    r"|CopyProcessingSpec\.setFileMode\(Integer\).{0,40}deprecated"
    r"|\bw:\s+file://"
    r"|uses? or overrides? (?:a )?deprecated APIs?"
    r"|\bw:[^\n]*deprecated"
    r"|WARNING: A restricted method in java\.lang\.System"
    r"|Invocation of Task\.project at execution time has been deprecated"
    r"|Deprecated Gradle features were used in this build"
    r"|(?:AGP|Gradle|Android Gradle plugin).{0,120}not supported.{0,80}Kotlin",
    re.IGNORECASE,
)


def check(text: str) -> list[str]:
    return [line.strip() for line in text.splitlines() if PROBLEMS.search(line)]


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: python tool/check_android_build_log.py BUILD_LOG", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    if "BUILD FAILED" in text or ("BUILD SUCCESSFUL" not in text and not re.search(r"Built .+\.(?:apk|aab)\b", text)):
        print("Build log does not confirm a completed successful build.", file=sys.stderr)
        return 1
    problems = check(text)
    if problems:
        print(f"Android build diagnostic gate: {len(problems)} diagnostics", file=sys.stderr)
        print("\n".join(problems[:12]), file=sys.stderr)
        return 1
    print("Android build log: compiler, native deprecation, SDK XML and font checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
