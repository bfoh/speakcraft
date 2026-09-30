#!/usr/bin/env python3
"""Validate canonical content and package the identical bytes for Flutter."""

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "curriculum/alpha.json"
TARGET = ROOT / "mobile/assets/curriculum/alpha.json"
TITLES = [
    "This Is Me",
    "My Salon",
    "Welcome a Customer",
    "Recommend",
    "Salon Challenge",
]


def validate(data: dict) -> None:
    if data["schema_version"] != 1 or data["profession"] != "beauty-cosmetology":
        raise ValueError("Unsupported curriculum schema or pathway")
    lessons = data["lessons"]
    if [x["title"] for x in lessons] != TITLES:
        raise ValueError("Alpha needs the five blueprint lessons in order")
    ids = set()
    for day, lesson in enumerate(lessons, 1):
        if lesson["day"] != day or lesson["id"] != f"day-{day}":
            raise ValueError("Lesson identity or order is invalid")
        for key in ("objective", "challenge", "target_language", "prompts"):
            if not lesson[key]:
                raise ValueError(f"Missing {key}")
        if not 1 <= lesson["estimated_minutes"] <= 30:
            raise ValueError("Invalid duration")
        for prompt in lesson["prompts"]:
            if prompt["id"] in ids:
                raise ValueError("Duplicate prompt ID")
            ids.add(prompt["id"])
            for key in ("id", "instruction", "example", "hint"):
                if not isinstance(prompt[key], str) or not prompt[key].strip():
                    raise ValueError(f"Invalid prompt {key}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = SOURCE.read_bytes()
    validate(json.loads(content))
    if args.check:
        if not TARGET.exists() or TARGET.read_bytes() != content:
            raise SystemExit(
                "Curriculum asset is stale. Run python3 scripts/sync_curriculum.py"
            )
    else:
        TARGET.parent.mkdir(parents=True, exist_ok=True)
        TARGET.write_bytes(content)
    print("Curriculum valid; mobile asset matches canonical content.")


if __name__ == "__main__":
    main()
