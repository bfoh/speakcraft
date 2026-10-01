"""Read the same authored Alpha objectives packaged with the mobile app."""

import json
from functools import lru_cache
from importlib.resources import files
from typing import Any, cast

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


class ConversationContext(BaseModel):
    lesson_id: str
    title: str
    opening: str
    goal: str
    turn_limit: int
    success_conditions: list[str]
    target_language: list[str]


@lru_cache(maxsize=1)
def _content() -> dict[str, Any]:
    return cast(
        dict[str, Any],
        json.loads(files("app").joinpath("data", "alpha.json").read_text()),
    )


@lru_cache(maxsize=1)
def _prompts() -> dict[tuple[str, str], PromptContext]:
    result: dict[tuple[str, str], PromptContext] = {}
    for lesson in _content()["lessons"]:
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


@lru_cache(maxsize=1)
def conversation_context(lesson_id: str) -> ConversationContext | None:
    for lesson in _content()["lessons"]:
        if lesson["id"] == lesson_id and "conversation" in lesson:
            conversation = lesson["conversation"]
            return ConversationContext(
                lesson_id=lesson_id,
                title=lesson["title"],
                opening=conversation["opening"],
                goal=conversation["goal"],
                turn_limit=conversation["turn_limit"],
                success_conditions=conversation["success_conditions"],
                target_language=lesson["target_language"],
            )
    return None
