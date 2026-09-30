"""Load and provide simple access to the academic knowledge-base JSON."""

import json
from pathlib import Path
from typing import Any


class KnowledgeBase:
    """Read the project knowledge base once and expose its stored data."""

    def __init__(self, file_path: str | Path | None = None) -> None:
        project_root = Path(__file__).resolve().parent.parent
        requested_path = Path(file_path) if file_path is not None else project_root / "data" / "knowledge_base.json"

        if not requested_path.is_absolute():
            requested_path = project_root / requested_path

        if file_path is None and not requested_path.exists():
            candidates = sorted((project_root / "data").glob("*knowledge*base*.json"))
            if len(candidates) == 1:
                requested_path = candidates[0]

        self.file_path = requested_path
        try:
            with self.file_path.open("r", encoding="utf-8") as json_file:
                self.data: dict[str, Any] = json.load(json_file)
        except FileNotFoundError as error:
            raise FileNotFoundError(
                f"Knowledge base not found: {self.file_path}. "
                "Place the JSON file at data/knowledge_base.json or pass its path to KnowledgeBase."
            ) from error
        except json.JSONDecodeError as error:
            raise ValueError(
                f"Invalid JSON in knowledge base {self.file_path}: "
                f"{error.msg} (line {error.lineno}, column {error.colno})."
            ) from error

    def get(self, key: str, default: Any = None) -> Any:
        """Return one top-level section, or the provided default if absent."""
        return self.data.get(key, default)

    def get_section(self, key: str) -> Any:
        """Return a top-level knowledge-base section or raise KeyError."""
        return self.data[key]