#!/usr/bin/env python3
"""Validate canonical content and package identical bytes for both runtimes."""

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "curriculum/alpha.json"
TARGETS = [
    ROOT / "mobile/assets/curriculum/alpha.json",
    ROOT / "backend/app/data/alpha.json",
]
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
    baseline = data.get("baseline_items")
    expected_baseline = [
        ("baseline-introduction", 1),
        ("baseline-picture", 2),
        ("baseline-procedure", 3),
        ("baseline-listening", 4),
        ("baseline-customer-1", 5),
        ("baseline-customer-2", 5),
        ("baseline-customer-3", 5),
    ]
    if not isinstance(baseline, list) or len(baseline) != len(expected_baseline):
        raise ValueError("Alpha needs seven baseline recording items")
    for index, item in enumerate(baseline):
        item_id, part = expected_baseline[index]
        if (
            not isinstance(item, dict)
            or item.get("id") != item_id
            or item.get("part") != part
        ):
            raise ValueError("Invalid baseline item identity or order")
        for key, limit in (("title", 80), ("instruction", 240), ("spoken_prompt", 240)):
            value = item.get(key)
            if not isinstance(value, str) or not value.strip() or len(value) > limit:
                raise ValueError(f"Invalid baseline {key}")
    challenge = data.get("day5_challenge_items")
    expected_challenge = [
        ("day5-need", 1),
        ("day5-greeting", 2),
        ("day5-question", 3),
        ("day5-recommend", 4),
        ("day5-close", 5),
    ]
    if not isinstance(challenge, list) or len(challenge) != len(expected_challenge):
        raise ValueError("Alpha needs five Day-5 challenge recording items")
    for index, item in enumerate(challenge):
        item_id, part = expected_challenge[index]
        if (
            not isinstance(item, dict)
            or item.get("id") != item_id
            or item.get("part") != part
        ):
            raise ValueError("Invalid Day-5 challenge identity or order")
        for key, limit in (("title", 80), ("instruction", 240), ("spoken_prompt", 240)):
            value = item.get(key)
            if not isinstance(value, str) or not value.strip() or len(value) > limit:
                raise ValueError(f"Invalid Day-5 challenge {key}")
    review_items = data.get("review_items")
    if not isinstance(review_items, list) or len(review_items) != 10:
        raise ValueError("Alpha needs ten authored review items")
    review_ids = set()
    for item in review_items:
        if not isinstance(item, dict) or not isinstance(item.get("day"), int):
            raise ValueError("Invalid review item")
        if not 1 <= item["day"] <= 5:
            raise ValueError("Invalid review day")
        for key, max_length in (("id", 48), ("text", 160), ("cue", 120)):
            value = item.get(key)
            if (
                not isinstance(value, str)
                or not value.strip()
                or len(value) > max_length
            ):
                raise ValueError(f"Invalid review {key}")
        if item["id"] in review_ids:
            raise ValueError("Duplicate review ID")
        review_ids.add(item["id"])
    scenarios = data.get("salon_scenarios")
    if not isinstance(scenarios, list) or len(scenarios) != 3:
        raise ValueError("Alpha needs three authored salon scenarios")
    expected_scenarios = [
        ("friendly-braids-price", 1, 4),
        ("welcome-needs-consultation", 2, 4),
        ("complete-salon-conversation", 3, 6),
    ]
    for index, scenario in enumerate(scenarios):
        scenario_id, difficulty, turn_limit = expected_scenarios[index]
        if scenario.get("id") != scenario_id:
            raise ValueError("Unexpected salon scenario")
        if (
            scenario.get("difficulty") != difficulty
            or scenario.get("turn_limit") != turn_limit
        ):
            raise ValueError("Invalid salon difficulty or turn limit")
        for key in (
            "scenario_goal",
            "customer_goal",
            "customer_personality",
            "customer_opening",
        ):
            if not isinstance(scenario.get(key), str) or not scenario[key].strip():
                raise ValueError(f"Invalid salon {key}")
        for key in ("learner_objectives", "target_language", "success_conditions"):
            values = scenario.get(key)
            if (
                not isinstance(values, list)
                or not values
                or any(
                    not isinstance(value, str) or not value.strip() for value in values
                )
            ):
                raise ValueError(f"Invalid salon {key}")
    ids = set()
    for day, lesson in enumerate(lessons, 1):
        if lesson["day"] != day or lesson["id"] != f"day-{day}":
            raise ValueError("Lesson identity or order is invalid")
        for key in ("objective", "challenge", "target_language", "prompts"):
            if not lesson[key]:
                raise ValueError(f"Missing {key}")
        if len(lesson["prompts"]) < (4 if day in (1, 5) else 3):
            raise ValueError(f"Day {day} needs its authored practice sequence")
        if not 1 <= lesson["estimated_minutes"] <= 30:
            raise ValueError("Invalid duration")
        conversation = lesson.get("conversation")
        if day == 1:
            if not isinstance(conversation, dict):
                raise ValueError("Day 1 needs a conversation")
            if conversation.get("turn_limit") != 3:
                raise ValueError("Day 1 conversation needs three turns")
            for key in ("opening", "goal"):
                if (
                    not isinstance(conversation.get(key), str)
                    or not conversation[key].strip()
                ):
                    raise ValueError(f"Invalid conversation {key}")
            conditions = conversation.get("success_conditions")
            if (
                not isinstance(conditions, list)
                or not conditions
                or any(not isinstance(x, str) or not x.strip() for x in conditions)
            ):
                raise ValueError("Invalid conversation success conditions")
        elif conversation is not None:
            raise ValueError("Only Day 1 conversation is authored")
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
        if any(
            not target.exists() or target.read_bytes() != content for target in TARGETS
        ):
            raise SystemExit(
                "Curriculum asset is stale. Run python3 scripts/sync_curriculum.py"
            )
    else:
        for target in TARGETS:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(content)
    print("Curriculum valid; mobile and backend assets match canonical content.")


if __name__ == "__main__":
    main()
