class_name WarbandStats
extends RefCounted
## One stat calculation shared by combat, draft previews and opponent decisions.

static func modified(base_value: int, stat_name: String, side_config: Dictionary) -> float:
    if base_value == 0:
        return 0.0
    var value := float(base_value)
    var set_bonus: Dictionary = side_config.get("set_bonus", {})
    if str(set_bonus.get("stat", "")) == stat_name and str(set_bonus.get("trigger", "")).is_empty():
        value *= 1.0 + float(set_bonus.get("percentage", 0)) / 100.0
    for raw_buff_state in side_config.get("buffs", []):
        if not raw_buff_state is Dictionary:
            continue
        var definition: Dictionary = raw_buff_state.get("definition", {})
        if str(definition.get("stat", "")) != stat_name:
            continue
        var stacks := maxi(0, int(raw_buff_state.get("stacks", 0)))
        var enhanced := clampi(int(raw_buff_state.get("sudden_death_stacks", 0)), 0, stacks)
        var percentage := float(definition.get("percentage", 0)) / 100.0
        var multiplier := 1.0 + percentage
        var enhanced_multiplier := 1.0 + percentage * float(raw_buff_state.get("sudden_death_multiplier", 2))
        value = exp(minf(log(1.0e100), log(maxf(1.0e-20, value)) + float(stacks - enhanced) * log(multiplier) + float(enhanced) * log(enhanced_multiplier)))
    return round(value)

static func power_percentage(side: Dictionary, buff: Dictionary) -> float:
    return float(buff.get("percentage", 0)) * (float(side.get("sudden_death_power_multiplier", 2)) if bool(side.get("sudden_death", false)) else 1.0)

static func effective(base_value: int, stat_name: String, side_config: Dictionary, rules: Dictionary) -> float:
    var value := modified(base_value, stat_name, side_config)
    if stat_name in ["attack_speed", "movement_speed"]:
        return clampf(value, 1, float(rules.get(stat_name + "_cap", 200)))
    return value

static func power_preview(side: Dictionary, buff: Dictionary, rules: Dictionary) -> Dictionary:
    var next := side.duplicate(true)
    var found := false
    if not next.has("buffs"):
        next["buffs"] = []
    for entry in next["buffs"]:
        if entry.get("definition", {}).get("id") == buff.get("id"):
            entry["stacks"] = int(entry.get("stacks", 0)) + 1
            if bool(side.get("sudden_death", false)):
                entry["sudden_death_stacks"] = int(entry.get("sudden_death_stacks", 0)) + 1
                entry["sudden_death_multiplier"] = float(side.get("sudden_death_power_multiplier", 2))
            found = true
    if not found:
        var entry := {"definition": buff.duplicate(true), "stacks": 1}
        if bool(side.get("sudden_death", false)):
            entry["sudden_death_stacks"] = 1
            entry["sudden_death_multiplier"] = float(side.get("sudden_death_power_multiplier", 2))
        next["buffs"].append(entry)
    var stat := str(buff.get("stat", ""))
    var result := {"total": 0, "improved": 0, "capped": 0, "rows": [], "before": 0.0, "after": 0.0, "stat": stat}
    for card in side.get("cards", []):
        var count := int(side.get("unit_counts", {}).get(str(card.get("id", "")), 0))
        if count <= 0:
            continue
        var base := int(card.get("stats", {}).get(stat, 0))
        var before := effective(base, stat, side, rules)
        var after := effective(base, stat, next, rules)
        result["total"] += count
        result["before"] += before * count
        result["after"] += after * count
        if after > before:
            result["improved"] += count
        if stat in ["attack_speed", "movement_speed"] and before >= float(rules.get(stat + "_cap", 200)):
            result["capped"] += count
        result["rows"].append({"name": str(card.get("display_name", "Companion")), "count": count, "before": before, "after": after})
    return result
