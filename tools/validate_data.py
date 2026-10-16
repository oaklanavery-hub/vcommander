#!/usr/bin/env python3
"""Validate VCommander JSON content and cross-references."""

from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def read_group(path: Path, recursive: bool = False) -> dict[str, dict]:
    pattern = "**/*.json" if recursive else "*.json"
    result: dict[str, dict] = {}
    for file_path in sorted(path.glob(pattern)):
        with file_path.open("r", encoding="utf-8") as handle:
            item = json.load(handle)
        content_id = item.get("id")
        if not content_id:
            raise ValueError(f"Missing id: {file_path}")
        if content_id in result:
            raise ValueError(f"Duplicate id {content_id}: {file_path}")
        if item.get("schema_version") != 1:
            raise ValueError(f"Unsupported schema_version in {file_path}")
        result[content_id] = item
    return result


def main() -> int:
    commanders = read_group(ROOT / "data" / "commanders")
    cards = read_group(ROOT / "data" / "cards", recursive=True)
    sets = read_group(ROOT / "data" / "sets")

    if len(commanders) != 3 or len(cards) != 12 or len(sets) != 3:
        raise ValueError(
            f"Phase 0 expects 3 commanders, 12 cards, 3 sets; got "
            f"{len(commanders)}, {len(cards)}, {len(sets)}"
        )

    for commander in commanders.values():
        set_id = commander.get("signature_set_id")
        if set_id not in sets:
            raise ValueError(f"Commander {commander['id']} references unknown set {set_id}")

    for signature_set in sets.values():
        required = signature_set.get("required_card_ids", [])
        required_count = signature_set.get("required_count")
        if required_count != 4 or len(required) != 4 or len(set(required)) != 4:
            raise ValueError(f"Set {signature_set['id']} must contain four unique required cards")
        for card_id in required:
            if card_id not in cards:
                raise ValueError(f"Set {signature_set['id']} references unknown card {card_id}")
            if cards[card_id].get("set_id") != signature_set["id"]:
                raise ValueError(f"Card {card_id} points at a different set")
            if cards[card_id].get("element") != signature_set.get("element"):
                raise ValueError(f"Card {card_id} element differs from its set")

    print(f"Data OK: {len(commanders)} commanders, {len(cards)} cards, {len(sets)} sets")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, json.JSONDecodeError) as exc:
        print(f"DATA VALIDATION FAILED: {exc}", file=sys.stderr)
        raise SystemExit(1)
