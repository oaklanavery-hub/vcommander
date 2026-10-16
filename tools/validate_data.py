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


def require_positive_number(value, label: str) -> None:
    if not isinstance(value, (int, float)) or value <= 0:
        raise ValueError(f"{label} must be a positive number")


def main() -> int:
    commanders = read_group(ROOT / "data" / "commanders")
    cards = read_group(ROOT / "data" / "cards", recursive=True)
    sets = read_group(ROOT / "data" / "sets")
    buffs = read_group(ROOT / "data" / "buffs")

    if (len(commanders), len(cards), len(sets), len(buffs)) != (3, 12, 3, 5):
        raise ValueError(
            "Starter slice expects 3 commanders, 12 cards, 3 sets and 5 buffs; "
            f"got {len(commanders)}, {len(cards)}, {len(sets)}, {len(buffs)}"
        )

    for commander in commanders.values():
        set_id = commander.get("signature_set_id")
        if set_id not in sets:
            raise ValueError(f"Commander {commander['id']} references unknown set {set_id}")
        skill = commander.get("active_skill", {})
        require_positive_number(skill.get("uses_per_match"), f"{commander['id']} uses_per_match")
        require_positive_number(skill.get("uses_per_round"), f"{commander['id']} uses_per_round")
        require_positive_number(skill.get("selection_cost"), f"{commander['id']} selection_cost")

    cards_by_set: dict[str, list[dict]] = {set_id: [] for set_id in sets}
    required_stats = ("health", "attack", "defense", "attack_speed", "movement_speed", "range")
    for army_card in cards.values():
        set_id = army_card.get("set_id")
        if set_id not in sets:
            raise ValueError(f"Card {army_card['id']} references unknown set {set_id}")
        cards_by_set[set_id].append(army_card)

        summon_amount = army_card.get("summon_amount")
        unit_cap = army_card.get("unit_cap")
        require_positive_number(summon_amount, f"{army_card['id']} summon_amount")
        require_positive_number(unit_cap, f"{army_card['id']} unit_cap")
        if summon_amount > unit_cap:
            raise ValueError(f"{army_card['id']} summon_amount cannot exceed unit_cap")

        stats = army_card.get("stats", {})
        for stat_name in required_stats:
            require_positive_number(stats.get(stat_name), f"{army_card['id']} stats.{stat_name}")

        ability = army_card.get("ability", {})
        if not ability.get("id") or not ability.get("type"):
            raise ValueError(f"{army_card['id']} must define an ability id and type")

    for set_id, signature_set in sets.items():
        if signature_set.get("required_count") != 4:
            raise ValueError(f"Set {set_id} required_count must be 4")
        if signature_set.get("activation") != "all_equipped_cards_match_set":
            raise ValueError(f"Set {set_id} uses unsupported activation rule")
        if len(cards_by_set[set_id]) < 4:
            raise ValueError(f"Set {set_id} needs at least four available themed cards")

        bonus = signature_set.get("bonus", {})
        require_positive_number(bonus.get("percentage"), f"{set_id} bonus.percentage")
        if bonus.get("stacking") != "multiplicative":
            raise ValueError(f"Set {set_id} bonus must stack multiplicatively")

    for buff in buffs.values():
        require_positive_number(buff.get("percentage"), f"{buff['id']} percentage")
        if buff.get("max_stacks") != 3:
            raise ValueError(f"{buff['id']} max_stacks must be 3")
        if buff.get("stacking") != "multiplicative":
            raise ValueError(f"{buff['id']} must stack multiplicatively")

    print(
        f"Data OK: {len(commanders)} commanders, {len(cards)} cards, "
        f"{len(sets)} sets, {len(buffs)} buffs"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, json.JSONDecodeError) as exc:
        print(f"DATA VALIDATION FAILED: {exc}", file=sys.stderr)
        raise SystemExit(1)
