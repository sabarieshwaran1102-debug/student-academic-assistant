"""Understand common student questions using explicit keyword and regex rules."""

import re


_INTENT_RULES: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("NEXT_CLASS", (r"\b(next|upcoming)\s+(class|lecture|period)\b", r"\bwhat('?s| is) next\b")),
    ("FACULTY_FOR_CLASS", (r"\b(who|which faculty|which teacher)\b.{0,40}\b(teach|take|handle)\b", r"\b(who teaches|faculty for|teacher for|taught by)\b")),
    ("EXAM_PERIOD", (r"\b(exam|examination)\b.{0,25}\b(period|date|schedule|when)\b", r"\b(when|dates?)\b.{0,25}\b(exam|examination)\b")),
    ("CLASS_TIME", (r"\b(when|what time)\b.{0,35}\b(class|lecture|period|course)\b", r"\b(class|lecture|period) time\b")),
    ("CLASS_VENUE", (r"\b(where|which room|which venue)\b.{0,35}\b(class|lecture|room|venue)\b", r"\b(class|classroom) (venue|room|location)\b")),
    ("UNIT_TOPICS", (r"\b(topics|contents)\b.{0,25}\b(unit|module)\b", r"\b(unit|module)\s+[ivx0-9]+\b.{0,25}\b(topics|contents)\b")),
    ("SYLLABUS_TOPIC_LOCATION", (r"\b(which|what)\s+unit\b.{0,40}\b(topic|syllabus|covers?|contains?|includes?)\b", r"\b(where|which unit)\b.{0,40}\b(syllabus|topic)\b")),
    ("TOPIC_INFORMATION", (r"\b(explain|define|meaning of)\b", r"\b(topic|concept)\s+(information|details|explanation)\b", r"\btell me about\b.{0,20}\b(topic|concept)\b")),
    ("MINI_PROJECT_MENTOR", (r"\b(mentor|guide)\b",)),
    ("MINI_PROJECT_DOMAIN", (r"\b(project|mini project)\b.{0,25}\b(domain|area)\b", r"\b(domain|area)\b.{0,25}\b(project|batch)\b")),
    ("MINI_PROJECT_BATCH", (r"\b(project|mini project)\b.{0,25}\b(batch|team|group)\b", r"\b(batch|team|group)\b.{0,25}\b(project|mentor|members)\b")),
    ("STUDENT_BATCH_LOOKUP", (r"\b(which|what)\s+batch\b", r"\b(batch|team|group)\b.{0,20}\b(student|belongs|member)\b")),
    ("HOLIDAY_CHECK", (r"\b(is|are)\b.{0,25}\b(holiday|holidays|working day|class)\b", r"\bholiday\b")),
    ("INTERNAL_TEST", (r"\b(internal|cycle)\s*(test|exam|assessment)\b", r"\b(internal test|internal exam|cia)\b")),
    ("ACADEMIC_CALENDAR", (r"\b(academic calendar|semester calendar|calendar events?)\b", r"\b(events?|semester starts?|semester ends?)\b")),
    ("CLASS_BY_DAY", (r"\b(classes|class|timetable|schedule)\b.{0,30}\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday|today|tomorrow)\b", r"\b(what|which)\s+(classes|class)\b")),
    ("FACULTY_INFORMATION", (r"\b(faculty|teacher|professor)\b.{0,25}\b(information|details|profile|expertise)\b", r"\b(who is|tell me about)\b.{0,25}\b(faculty|teacher|professor|advisor|tutor)\b")),
    ("SUBJECT_INFORMATION", (r"\b(subject|course)\b.{0,25}\b(information|details|credits|hours|prerequisite|syllabus)\b", r"\b(tell me about|information about|details of)\b.{0,30}\b(subject|course)\b")),
)


def detect_intent(text: str, tokens: list[str] | None = None) -> str:
    """Return the first matching intent, checking specific rules before broad ones."""
    normalized = " ".join(tokens) if tokens is not None else text.lower()
    normalized = re.sub(r"\s+", " ", normalized).strip()

    for intent, patterns in _INTENT_RULES:
        if any(re.search(pattern, normalized) for pattern in patterns):
            return intent

    return "UNKNOWN"