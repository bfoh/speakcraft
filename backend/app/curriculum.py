"""Read the same authored Alpha objectives packaged with the mobile app."""

import json
from functools import lru_cache
from importlib.resources import files

from pydantic import BaseModel


class PromptContext(BaseModel):
    lesson_id: str
    lesson_title: str
    objective: str
    target_language: list[str]
    prompt_id: str
    instruction: str
    example: str
    hint: str


@lru_cache(maxsize=1)
def _prompts() -> dict[tuple[str, str], PromptContext]:
    content = files("app").joinpath("data", "alpha.json").read_text()
    data = json.loads(content)
    result: dict[tuple[str, str], PromptContext] = {}
    for lesson in data["lessons"]:
        for prompt in lesson["prompts"]:
            context = PromptContext(
                lesson_id=lesson["id"],
                lesson_title=lesson["title"],
                objective=lesson["objective"],
                target_language=lesson["target_language"],
                prompt_id=prompt["id"],
                instruction=prompt["instruction"],
                example=prompt["example"],
                hint=prompt["hint"],
            )
            result[(context.lesson_id, context.prompt_id)] = context
    return result


def prompt_context(lesson_id: str, prompt_id: str) -> PromptContext | None:
    return _prompts().get((lesson_id, prompt_id))
