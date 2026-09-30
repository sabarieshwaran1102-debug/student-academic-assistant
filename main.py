"""Run a small interactive test of the classical NLP pipeline."""

import json

from knowledge import KnowledgeBase
from nlp import detect_intent, extract_entities, normalize_text, tokenize
from response import generate_response


def main() -> None:
    """Load the existing JSON and print intent/entity detection for each question."""
    try:
        knowledge_base = KnowledgeBase()
    except (FileNotFoundError, ValueError) as error:
        print(f"Could not load the knowledge base: {error}")
        return

    print(f"Knowledge base loaded from: {knowledge_base.file_path}")
    while True:
        try:
            question = input("\nAsk an academic question (blank to quit): ")
        except EOFError:
            print()
            break
        if not question.strip():
            break

        normalized = normalize_text(question)
        tokens = tokenize(normalized)
        intent = detect_intent(normalized, tokens)
        entities = extract_entities(normalized, knowledge_base)
        answer = generate_response(intent, entities, knowledge_base)

        print(f"Normalized: {normalized}")
        print(f"Tokens: {tokens}")
        print(f"Intent: {intent}")
        print(f"Entities: {json.dumps(entities, ensure_ascii=False, indent=4)}")
        print(f"Answer: {answer}")


if __name__ == "__main__":
    main()