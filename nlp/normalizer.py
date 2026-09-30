"""Normalize user text with small, predictable standard-library rules."""

import re
import unicodedata


def normalize_text(text: str) -> str:
    """Lowercase text, preserve useful code/date/time punctuation, and trim spaces."""
    normalized = text.lower().replace("'", "")
    normalized = "".join(
        character
        if character.isalnum()
        or unicodedata.category(character).startswith("M")
        or character.isspace()
        or character in ":/-"
        else " "
        for character in normalized
    )
    return re.sub(r"\s+", " ", normalized).strip()