#!/usr/bin/env python3
"""Fail CI when committed res:// file references point at missing files."""

from __future__ import annotations

import re
import sys
from pathlib import Path


CHECKED_SUFFIXES = {
    ".cfg",
    ".gd",
    ".gdshader",
    ".import",
    ".tres",
    ".tscn",
}

REFERENCE_RE = re.compile(r"res://[^\"')\],\s]+")


def should_check(path: Path) -> bool:
    return path.name == "project.godot" or path.suffix in CHECKED_SUFFIXES


def is_ignored_reference(reference: str) -> bool:
    return reference.startswith("res://.godot/") or reference.endswith("/")


def reference_to_path(reference: str) -> Path:
    return Path(reference.split("::", 1)[0].removeprefix("res://"))


def main() -> int:
    root = Path.cwd()
    missing: list[str] = []

    for path in sorted(root.rglob("*")):
        if not path.is_file() or ".git" in path.parts or ".godot" in path.parts or not should_check(path):
            continue

        text = path.read_text(encoding="utf-8", errors="ignore")
        for match in REFERENCE_RE.finditer(text):
            reference = match.group(0)
            if is_ignored_reference(reference):
                continue

            target = root / reference_to_path(reference)
            if not target.exists():
                line = text.count("\n", 0, match.start()) + 1
                missing.append(f"{path}:{line}: {reference}")

    if missing:
        print("Missing res:// targets:")
        for item in missing:
            print(f"  {item}")
        return 1

    print("All committed res:// file references exist.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
