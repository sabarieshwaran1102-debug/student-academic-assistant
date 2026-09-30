"""A basic regular-expression tokenizer for normalized user text."""

import re
import unicodedata


_TOKEN_PATTERN = re.compile(
    r"\d{1,2}:\d{2}(?:\s*[ap]m)?"
    r"|\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?",
    re.IGNORECASE,
)


def _is_word_character(character: str) -> bool:
    """Include Unicode combining marks omitted by regular-expression word classes."""
    return character.isalnum() or unicodedata.category(character).startswith("M")


def tokenize(text: str) -> list[str]:
    """Return word, code, date, and time tokens from normalized text."""
    tokens: list[str] = []
    position = 0

    while position < len(text):
        special_token = _TOKEN_PATTERN.match(text, position)
        if special_token:
            tokens.append(special_token.group())
            position = special_token.end()
            continue

        if not _is_word_character(text[position]):
            position += 1
            continue

        start = position
        position += 1
        while position < len(text):
            if _is_word_character(text[position]):
                position += 1
            elif (
                text[position] in "-'"
                and position + 1 < len(text)
                and _is_word_character(text[position + 1])
            ):
                position += 1
            else:
                break
        tokens.append(text[start:position])

    return tokens