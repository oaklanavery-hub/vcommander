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
    balances = read_group(ROOT / "data" / "balance")

    if not all((commanders, cards, sets, buffs)) or len(balances) != 1:
        raise ValueError("Content groups must be nonempty with exactly one global balance file")

    for commander in commanders.values():
        set_id = commander.get("signature_set_id")
        if set_id not in sets:
            raise ValueError(f"Commander {commander['id']} references unknown set {set_id}")
        skill = commander.get("active_skill", {})
        if not skill.get("id") or not skill.get("type"):
            raise ValueError(f"{commander['id']} active_skill must define id and type")
        require_positive_number(skill.get("uses_per_match"), f"{commander['id']} uses_per_match")
        require_positive_number(skill.get("uses_per_round"), f"{commander['id']} uses_per_round")
        require_positive_number(skill.get("selection_cost"), f"{commander['id']} selection_cost")
        if skill.get("type") == "army_revival":
            require_positive_number(skill.get("revives_per_unit"), "revives_per_unit")
            require_positive_number(skill.get("revive_health_pct"), "revive_health_pct")
            if skill["revive_health_pct"] > 100:
                raise ValueError("revive_health_pct cannot exceed 100")

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
        if ability.get("type") == "backline_transit":
            for key in ("cooldown_seconds", "transit_seconds"):
                require_positive_number(ability.get(key), f"{army_card['id']} {key}")
            if ability.get("mode") not in ("flame", "gush", "burrow") or type(ability.get("invulnerable")) is not bool:
                raise ValueError("backline_transit requires a supported mode and explicit immunity")
            mode_fields = {"flame": ("trail_seconds", "trail_radius", "tick_seconds", "damage_attack_pct_per_tick"), "gush": ("contact_radius", "attack_pct"), "burrow": ("obstacle_seconds", "every_n_attacks", "attack_pct")}
            for key in mode_fields[ability["mode"]]:
                require_positive_number(ability.get(key), f"{army_card['id']} {key}")
        if ability.get("type") == "damage_link":
            for key in ("cooldown_seconds", "duration_seconds", "link_radius", "shared_damage_pct"):
                require_positive_number(ability.get(key), f"{army_card['id']} {key}")
            if ability.get("max_targets") != 2 or ability["shared_damage_pct"] > 100:
                raise ValueError("damage_link supports up to two targets and at most 100% copied damage")
        if ability.get("type") == "death_split":
            for key in ("spawn_count", "child_health_pct", "child_attack_pct", "child_visual_scale"):
                require_positive_number(ability.get(key), f"{army_card['id']} {key}")
            if ability.get("trigger") != "on_death":
                raise ValueError("death_split must trigger on_death")
        if ability.get("type") == "ranged_aoe_slow":
            require_positive_number(ability.get("slow_seconds"), "slow_seconds")
            for key in ("enemy_attack_speed_pct", "enemy_movement_speed_pct"):
                if not isinstance(ability.get(key), (int, float)) or not -100 < ability[key] < 0:
                    raise ValueError(f"{key} must be a negative percentage above -100")
        if ability.get("type") == "death_damage_area":
            for key in ("duration_seconds", "tick_seconds", "attack_pct", "damage_attack_pct_per_tick"):
                require_positive_number(ability.get(key), f"{army_card['id']} {key}")
            if ability.get("trigger") != "on_death":
                raise ValueError("death_damage_area must trigger on_death")
        if ability.get("type") == "absorb_burst":
            for key in ("absorb_pct", "burst_seconds", "death_multiplier"):
                require_positive_number(ability.get(key), f"{army_card['id']} {key}")
            if ability["absorb_pct"] >= 100:
                raise ValueError("absorb_pct must be below 100")
            if ability.get("radius") not in ("small", "medium", "large"):
                raise ValueError("absorb_burst must define a supported radius")
            if ability.get("pushback") not in ("small", "moderate", "large"):
                raise ValueError("absorb_burst must define a supported pushback")

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
        if bonus.get("trigger", "") not in ("", "on_death_spawn"):
            raise ValueError(f"Set {set_id} uses an unsupported bonus trigger")
        if bonus.get("trigger") == "on_death_spawn" and bonus.get("stat") != "attack":
            raise ValueError("Death-spawn bonuses currently modify attack only")

    for buff in buffs.values():
        require_positive_number(buff.get("percentage"), f"{buff['id']} percentage")
        if type(buff.get("max_stacks")) is not int or buff["max_stacks"] < 0:
            raise ValueError(f"{buff['id']} max_stacks must be a nonnegative integer (0 means unlimited)")
        if buff.get("stacking") != "multiplicative":
            raise ValueError(f"{buff['id']} must stack multiplicatively")

    balance = balances.get("game_balance")
    if balance is None:
        raise ValueError("data/balance must contain id=game_balance")
    require_positive_number(
        balance.get("match", {}).get("round_time_seconds"),
        "game_balance match.round_time_seconds",
    )
    battlefield = balance.get("battlefield", {})
    require_positive_number(battlefield.get("width"), "game_balance battlefield.width")
    require_positive_number(battlefield.get("height"), "game_balance battlefield.height")
    simulation = balance.get("simulation", {})
    for key in (
        "step_seconds",
        "frame_interval_seconds",
        "collision_radius",
        "movement_units_per_second_at_100",
        "projectile_units_per_second",
    ):
        require_positive_number(simulation.get(key), f"game_balance simulation.{key}")

    formation = balance.get("formation", {})
    for key in ("spacing_units", "area_spread_multiplier", "maximum_rows"):
        require_positive_number(formation.get(key), f"game_balance formation.{key}")
    if formation["area_spread_multiplier"] < 1:
        raise ValueError("formation.area_spread_multiplier cannot reduce area-threat spacing")
    if not isinstance(formation["maximum_rows"], int):
        raise ValueError("formation.maximum_rows must be a whole number")

    progression = read_group(ROOT / "data" / "progression")
    mastery = progression.get("commander_mastery", {})
    if not isinstance(mastery.get("xp_per_level"), int) or isinstance(mastery.get("xp_per_level"), bool) or mastery["xp_per_level"] <= 0:
        raise ValueError("Mastery xp_per_level must be a positive whole number")
    for outcome, expected in {"win": 100, "loss": 25, "forfeit": 0}.items():
        if mastery.get("match_xp", {}).get(outcome) != expected:
            raise ValueError(f"Approved mastery {outcome} reward must be {expected}")
    legacy_cards = mastery.get("legacy_available_cards")
    if not isinstance(legacy_cards, list) or len(legacy_cards) != 20 or any(type(ident) is not str or ident not in cards for ident in legacy_cards) or len(set(legacy_cards)) != len(legacy_cards):
        raise ValueError("Legacy collection migration needs twenty unique existing card IDs")

    def positive_integer(value, label):
        if type(value) is not int or value < 1:
            raise ValueError(f"{label} must be a positive whole number")

    achievements = progression.get("achievements", {}).get("achievements", [])
    if not isinstance(achievements, list) or not achievements:
        raise ValueError("An achievement catalog is required")
    seen = set()
    for entry in achievements:
        ident = entry.get("id")
        if not ident or ident in seen or not entry.get("display_name") or not entry.get("description"):
            raise ValueError("Achievements need unique IDs, names and descriptions")
        seen.add(ident)
        commander = entry.get("commander_id", "")
        if commander and commander not in commanders:
            raise ValueError(f"Unknown achievement Commander: {commander}")
        conditions = entry.get("conditions")
        if not isinstance(conditions, list) or not conditions:
            raise ValueError(f"{ident} needs conditions")
        for condition in conditions:
            if condition.get("metric") not in {"wins", "completed", "level", "commanders_won"}:
                raise ValueError(f"Unsupported achievement metric in {ident}")
            if commander and condition["metric"] == "commanders_won":
                raise ValueError("Commander coverage is a global metric")
            positive_integer(condition.get("target"), f"{ident} target")
    for card in cards.values():
        requirement = card.get("mastery_unlock")
        tags = card.get("tags", [])
        if ("starter" in tags) != (requirement is None) or ("mastery_reward" in tags) != (requirement is not None):
            raise ValueError(f"{card['id']} collection tags must match its unlock requirement")
        if requirement is None:
            continue
        if not isinstance(requirement, dict) or requirement.get("commander_id") not in commanders:
            raise ValueError(f"{card['id']} needs a valid reward Commander")
        owner = commanders[requirement["commander_id"]]
        if card["set_id"] != owner["signature_set_id"]:
            raise ValueError("Mastery units must belong to their reward Commander's theme")
        positive_integer(requirement.get("level"), "mastery unlock level")
        positive_integer(requirement.get("wins"), "mastery unlock wins")
    for set_id, members in cards_by_set.items():
        if sum("mastery_unlock" not in card for card in members) < 4:
            raise ValueError(f"{set_id} needs four unlocked starter cards")

    print(
        f"Data OK: {len(commanders)} commanders, {len(cards)} cards, "
        f"{len(sets)} sets, {len(buffs)} buffs, {len(balances)} balance file"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, json.JSONDecodeError) as exc:
        print(f"DATA VALIDATION FAILED: {exc}", file=sys.stderr)
        raise SystemExit(1)
