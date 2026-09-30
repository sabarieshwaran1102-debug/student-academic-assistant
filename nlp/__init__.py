"""Classical text-processing modules for the Student Academic Assistant."""

from .entity import extract_entities
from .intent import detect_intent
from .normalizer import normalize_text
from .tokenizer import tokenize

__all__ = ["detect_intent", "extract_entities", "normalize_text", "tokenize"]