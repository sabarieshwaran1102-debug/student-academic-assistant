"""Extract dates and knowledge-base-backed academic names with simple rules."""

import re
from collections.abc import Mapping
from typing import Any

from knowledge.knowledge_base import KnowledgeBase
from .normalizer import normalize_text


_COURSE_CODE_PATTERN = re.compile(r"\b(?:\d{2}[a-z]{2,5}\d{3,4}|[a-z]{2,5}\d{3,4})\b", re.IGNORECASE)
_DATE_PATTERN = re.compile(
    r"\b(?:\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?|"
    r"\d{4}-\d{1,2}-\d{1,2}|"
    r"(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|"
    r"jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|"
    r"dec(?:ember)?)\s+\d{1,2}(?:,?\s+\d{4})?)\b",
    re.IGNORECASE,
)
_TIME_PATTERN = re.compile(r"\b(?:[01]?\d|2[0-3]):[0-5]\d(?:\s*[ap]m)?\b", re.IGNORECASE)
_BATCH_PATTERN = re.compile(r"\bbatch\s*(?:no\.?\s*)?(\d+)\b", re.IGNORECASE)
_UNIT_PATTERN = re.compile(r"\bunit\s+([ivxlcdm]+|\d+)\b", re.IGNORECASE)
_PERIOD_PATTERN = re.compile(
    r"\bperiod\s+([ivxlcdm]+|[1-7])\b|\b([1-7])(?:st|nd|rd|th)\s+period\b",
    re.IGNORECASE,
)


def _walk_values(value: Any):
    """Yield all strings and mapping keys in the knowledge-base structure."""
    if isinstance(value, Mapping):
        for key, child in value.items():
            yield str(key)
            yield from _walk_values(child)
    elif isinstance(value, (list, tuple)):
        for child in value:
            yield from _walk_values(child)
    elif isinstance(value, str):
        yield value


def _add_entity(entities: dict[str, Any], entity_type: str, value: str) -> None:
    """Keep one match as a string and preserve additional matches in a list."""
    current = entities.get(entity_type)
    if current is None:
        entities[entity_type] = value
    elif isinstance(current, list):
        if value not in current:
            current.append(value)
    elif current != value:
        entities[entity_type] = [current, value]


def _add_text_matches(
    entities: dict[str, Any], entity_type: str, text: str, values: set[str]
) -> None:
    """Match normalized knowledge-base phrases as whole phrases in the question."""
    for value in sorted(values, key=len, reverse=True):
        normalized_value = normalize_text(value)
        if normalized_value and f" {normalized_value} " in f" {text} ":
            _add_entity(entities, entity_type, value)


def extract_entities(text: str, knowledge_base: KnowledgeBase | Mapping[str, Any]) -> dict[str, Any]:
    """Extract rule-based entities, sourcing academic names from the loaded JSON."""
    data = knowledge_base.data if isinstance(knowledge_base, KnowledgeBase) else knowledge_base
    normalized = normalize_text(text)
    entities: dict[str, Any] = {}

    for match in _DATE_PATTERN.findall(normalized):
        _add_entity(entities, "DATE", match)
    for match in _TIME_PATTERN.findall(normalized):
        _add_entity(entities, "TIME", match)
    for match in _COURSE_CODE_PATTERN.findall(normalized):
        _add_entity(entities, "COURSE_CODE", match.upper())
    for match in _BATCH_PATTERN.finditer(normalized):
        _add_entity(entities, "BATCH", match.group(1))
    for match in _UNIT_PATTERN.finditer(normalized):
        _add_entity(entities, "UNIT", match.group(1).upper())
    for match in _PERIOD_PATTERN.finditer(normalized):
        _add_entity(entities, "PERIOD", (match.group(1) or match.group(2)).upper())

    days = {str(day) for day in data.get("timetable", {})}
    days.update({"today", "tomorrow"})
    _add_text_matches(entities, "DAY", normalized, days)

    courses = data.get("courses", {})
    course_codes = {str(code) for code in courses if re.fullmatch(_COURSE_CODE_PATTERN, str(code))}
    _add_text_matches(entities, "COURSE_CODE", normalized, course_codes)
    course_names = {
        str(course.get("title"))
        for course in courses.values()
        if isinstance(course, Mapping) and course.get("title")
    }
    _add_text_matches(entities, "COURSE_NAME", normalized, course_names)
    if "COURSE_NAME" not in entities:
        for title in course_names:
            words = normalize_text(title).split()
            for start in range(len(words)):
                for end in range(start + 2, len(words) + 1):
                    phrase = " ".join(words[start:end])
                    if f" {phrase} " in f" {normalized} ":
                        _add_entity(entities, "COURSE_NAME", phrase.title())

    faculty_names = {
        str(profile.get("name"))
        for profile in data.get("faculty", {}).get("profiles", [])
        if isinstance(profile, Mapping) and profile.get("name")
    }
    for faculty_list in data.get("timetable_staff_mapping", {}).values():
        faculty_names.update(str(name) for name in faculty_list)
    for key in ("class_advisor", "tutor"):
        name = data.get("class", {}).get(key)
        if name:
            faculty_names.add(str(name))
    _add_text_matches(entities, "FACULTY", normalized, faculty_names)

    topics: set[str] = set()
    for course in courses.values():
        if not isinstance(course, Mapping):
            continue
        for unit in course.get("units", {}).values():
            if isinstance(unit, Mapping):
                topics.update(str(topic) for topic in unit.get("topics", []))
    _add_text_matches(entities, "TOPIC", normalized, topics)

    students: set[str] = set()
    batches = data.get("mini_project", {}).get("batches", [])
    domains: set[str] = set()
    for batch in batches:
        if not isinstance(batch, Mapping):
            continue
        if batch.get("domain"):
            domains.add(str(batch["domain"]))
        students.update(str(member) for member in batch.get("members", []))
    _add_text_matches(entities, "STUDENT", normalized, students)
    _add_text_matches(entities, "DOMAIN", normalized, domains)

    return entities